pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main

sprites={}
cell_size=8
row_size=16
big_size=32
big_size=16
big_size=8
scalar=big_size/cell_size
function _init()
	_update=start_update
	_draw=start_draw
end

function start_update()
	if (btnp(🅾️)) then
		tt=0
		sprites={}

		world=world_init()

		player=player_new()
		player:init()
		add(sprites,player)

		add(sprites,ghost_new())
		init_skeleton()

		_update=game_update
		_draw=game_draw
	end
end

function start_draw()
	cls()
	local message="press 🅾️ to start"
	print(message,64-(#message*8)/4-2,64,7)
end

function game_update()
	tt=inc_tt(tt)
	update_sprites()
	sort_sprites()
	world:update()
end

function game_draw()
	palt(0,false)
	palt(9,true)
	world:draw()
	draw_sprites()
end

function over_update()
	if (btnp(🅾️)) then
		_update=start_update
		_draw=start_draw
	end
end

function over_draw()
	cls()
	local message="game over"
	print(message,64-(#message*8)/4,64,7)
end

function init_skeleton()
	local grave=rnd(world.graves)
	add(sprites,skeleton_new(grave.x,grave.y))
end

function update_sprites()
	foreach(sprites,function(sprite)
		sprite:update()
	end)
end

function draw_sprites()
	clip(0,64,128,64)
	foreach(sprites,function(sprite)
		sprite:draw_shadow()
	end)
	clip()
	foreach(sprites,function(sprite)
		sprite:draw()
	end)
end

function sort_sprites()
	for i=1,#sprites do
		for j=1,#sprites do
			if sprites[i].y<sprites[j].y then
				sprites[i],sprites[j]=sprites[j],sprites[i]
			end
		end
	end
end

function collision(a,b)
	return a.x1<b.x2 and a.x2>b.x1 and a.y1<b.y2 and a.y2>b.y1
end

function distance(a,b)
	local ax=(a.x1+a.x2)/2
	local ay=(a.y1+a.y2)/2
	local bx=(b.x1+b.x2)/2
	local by=(b.y1+b.y2)/2
	local dx=bx-ax
	local dy=by-ay
	return sqrt(dx*dx+dy*dy)
end

function zspr(frame,x,y,flip_x,flip_y)
	local sx=flr(frame%row_size)*cell_size
	local sy=flr(frame/row_size)*cell_size

	sspr(sx,sy,cell_size,cell_size,x,y,big_size,big_size,flip_x,flip_y)
end

function bspr(frame,x,y,flip_x,flip_y)
	spr(frame,x,y,4,4,flip_x,flip_y)
end

function zset(x,y,c)
	for j=0,scalar-1 do
		for k=0,scalar-1 do
			pset(x+j,y+k,c)
		end
	end
end

function draw_shadow_line(a,b,n,x,y)
	for d=1,3 do
		for j=1,a do
			for k=1,a do
				pset(x+n*b+d*a+j-a,y-d*a+k,0)
			end
		end
	end
end

function inc_tt(t0)
	return max(0,t0+1)
end
-->8
--player

player={}
player_speed=.25*scalar
friction=0.85
gravity=0.2*scalar
max_speed_x=1.5*scalar
max_speed_y=.85*scalar

function player_new()
	local x0,y0=47,90
	local self={
		type="player",
		x=x0,
		y=y0,
		dx=0,
		dy=0,
		tt=0,
		turned=false,
		frame_head=1,
		frame_body_idle=17,
		frame_body_walk={18, 17, 19},
		frame_body_walk_index=1,
		frame_lantern=4,
		boost=-1.7*scalar,
		vy=0,
		ty=0,
		hold_jump=0,
		ready_jump=true,
		go_jump=false,
	}

	function self:init()
		self:update_bounds()
		self:update_behind()
	end
	
	function self:update()
		self.tt=inc_tt(self.tt)
		self:get_input()
		self:collision()
		self:move()
		self:animate()
	end
	
	function self:draw()
		self:draw_lantern()
		self:draw_body()
		self:draw_head()
	end

	function self:get_input()
		local speed=player_speed
		self.dx*=friction
		self.dy*=friction
		if abs(self.dx)<0.1 then
			self.dx=0
		end
		if abs(self.dy)<0.1 then
			self.dy=0
		end
		if btn(⬅️) then
			self.dx-=speed
			self.turned=true
		end
		if btn(➡️) then
			self.dx+=speed
			self.turned=false
		end
		if btn(⬆️) then
			self.dy-=speed
		end
		if btn(⬇️) then
			self.dy+=speed
		end

		if not self.go_jump then
			if self.ready_jump and btn(❎) then
				self.hold_jump+=1
			elseif self.hold_jump>0 then
				self.go_jump=true
			end
		end

		if self.hold_jump>0 and self.go_jump then
			local a=mid(.5,self.hold_jump/5,1.2)
			self.vy=a*self.boost
			self.ready_jump=false
			self.hold_jump=0
		end
		if self.ty<0 then
			self.vy+=gravity
		end
		local mx=max_speed_x
		local my=max_speed_y
		if self.hold_jump>0 and not self.go_jump then
			mx*=0.25
			my*=0.25
		end
		if abs(self.dx)>mx then
			local sign=abs(self.dx)/self.dx
			self.dx=mx*sign
		end
		if abs(self.dy)>my then
			local sign=abs(self.dy)/self.dy
			self.dy=my*sign
		end
	end

	function self:collision()
		self:collision_floor()
		--self:collision_map()
		--self:collision_sprites()
	end

	function self:collision_floor()
		if self.vy>0 and self.ty>=0 and self.go_jump then
			self.ty=0
			self.vy=0
			self.ready_jump=true
			self.go_jump=false
		end
	end

	function self:collision_map()
		local x1=flr(self.x/cell_size)
		local y1=flr(self.y/cell_size)
		local x2=flr((self.x+big_size-1)/cell_size)
		local y2=flr((self.y+big_size-1)/cell_size)
		local x3=flr((self.x+big_size-1)/cell_size)
		local y3=flr(self.y/cell_size)
		local x4=flr(self.x/cell_size)
		local y4=flr((self.y+big_size-1)/cell_size)
	end

	function self:move()
		self.x+=self.dx
		self.y+=self.dy
		self.ty+=self.vy
		self:update_bounds()
		self:update_behind()
	end

	function self:update_bounds()
		self.x1=self.x
		self.x2=self.x+big_size
		self.y1=self.y+big_size*2-scalar
		self.y2=self.y+big_size*2+scalar
	end

	function self:update_behind()
		if self.turned then
			self.behind={
				x1=self.x1+big_size*2,
				x2=self.x2+big_size*2,
				y1=self.y1-big_size,
				y2=self.y2-big_size,
			}
		else
			self.behind={
				x1=self.x1-big_size*2,
				x2=self.x2-big_size*2,
				y1=self.y1-big_size,
				y2=self.y2-big_size,
			}
		end
		local sb=self.behind
		self.behind.x=(sb.x1+sb.x2)/2
		self.behind.y=(sb.y1+sb.y2)/2
	end

	function self:animate()
		self:animate_body()
	end

	function self:animate_body()
		if self.ty<0 then
			return
		end
		if self.dx==0 and self.dy==0 then
			self.frame_body_walk_index=1
		else
			if self.tt%4==0 then
				self.frame_body_walk_index+=1
			end
			if self.frame_body_walk_index>#self.frame_body_walk then
				self.frame_body_walk_index=1
			end
		end
	end

	function self:draw_head()
		local y=self.y+self.ty
		if self.hold_jump>0 then
			y+=1*scalar
		end
		zspr(self.frame_head,self.x,y,self.turned)
	end

	function self:get_frame_body()
		if self.dx==0 and self.dy==0 then
			return self.frame_body_idle
		else
			return self.frame_body_walk[self.frame_body_walk_index]
		end
	end

	function self:draw_body()
		local y=self.y+self.ty
		zspr(self:get_frame_body(),self.x,y+big_size,self.turned)
	end

	function self:draw_lantern()
		local x=self.x
		local y=self.y+self.ty+big_size/2+scalar
		if self.turned then
			x-=big_size-scalar
		else
			x+=big_size-scalar
		end
		if self.hold_jump>0 then
			y+=1*scalar
		end
		zspr(self.frame_lantern,x,y,self.turned)
		self:draw_flame(x,y)
	end

	function self:draw_flame(x,y)
		if self.turned then
			x-=1*scalar
		end
		for i=1,3 do
			local rx=flr(rnd(3)+1)*scalar+2*scalar
			local ry=flr(rnd(2)+1)*scalar+4*scalar
			zset(x+rx,y+ry,9)
		end
	end

	function self:draw_shadow()
		if self.ty<0 then
			self:draw_shadow_line(-1)
			self:draw_shadow_line(0)
			self:draw_shadow_line(1)
		end
	end

	function self:draw_shadow_line(n)
		local a=scalar
		local b=mid(big_size/4,self.ty*a/self.boost,big_size/2)
		local x=self.x+big_size/4
		local y=self.y+2*(big_size)

		draw_shadow_line(a,b,n,x,y)
	end

	function self:die()
		_update=over_update
		_draw=over_draw
	end
	
	return self
end
-->8
--ghost

ghost_speed=scalar
ghost_float_freq=1/100
ghost_float_amp=2
ghost_float_disp=10
ghost_near=big_size/4
ghost_close=5*big_size

function ghost_new()
	local x0=128
	if rnd(1)<.5 then
		x0=-big_size
	end
	local y0=flr(rnd(32))
	local self={
		type="ghost",
		x=x0,
		y=y0,
		dx=0,
		dy=0,
		tt=0,
		dist=128,
		hover_p=0,
		hover_y=0,
		turned=false,
		frame_head=33,
		frame_body={49,50,49,51},
		frame_body_index=1,
		x1=x0,
		x2=x0+big_size,
		y1=y0,
		y2=y0+big_size*2,
	}

	function self:update()
		self.tt=inc_tt(self.tt)
		self:move()
		self:animate()
	end

	function self:draw()
		self:draw_head()
		self:draw_body()
	end

	function self:move()
		self.dist=distance(self,player.behind)
		if self.dist<ghost_near then
			self.dx,self.dy=0,0
		else
			self:move_to_player()
		end
		self.x+=self.dx
		self.y+=self.dy
		if self.dx<0 then
			self.turned=true
		elseif self.dx>0 then
			self.turned=false
		end
		self:update_bounds()
	end

	function self:move_to_player()
		local a=ghost_speed
		if self.dist<ghost_near then
			a=ghost_speed/4
		elseif self.dist<ghost_close then
			a=ghost_speed/2
		end
		local p=player.behind
		local sx=(self.x1+self.x2)/2
		local sy=(self.y1+self.y2)/2
		local angle=atan2(p.x-sx,p.y-sy)
		self.dx=cos(angle)*a
		self.dy=sin(angle)*a/2
	end

	function self:update_bounds()
		self.x1=self.x
		self.x2=self.x+big_size
		self.y1=self.y
		self.y2=self.y+big_size*2
	end

	function self:animate()
		self:animate_body()
	end

	function self:animate_body()
		if self.tt%4==0 then
			self.frame_body_index+=1
		end
		if self.frame_body_index>#self.frame_body then
			self.frame_body_index=1
		end
		local a=scalar
		self.hover_p=cos(self.tt*ghost_float_freq)
		self.hover_y=a*self.hover_p*ghost_float_amp-a*ghost_float_disp
	end

	function self:draw_head()
		local x=self.x
		local y=self.y+self.hover_y
		zspr(self.frame_head,x,y,self.turned)
	end

	function self:get_frame_body()
		return self.frame_body[self.frame_body_index]
	end

	function self:draw_float_body()
		local x=self.x
		local y=self.y+self.hover_y+big_size
		zspr(self:get_frame_body(),x,y,self.turned)
	end

	function self:draw_body()
		local x=self.x
		local y=self.y+self.hover_y+big_size
		zspr(self:get_frame_body(),x,y,self.turned)
	end

	function self:draw_shadow()
		self:draw_shadow_line(-1)
		self:draw_shadow_line(0)
		self:draw_shadow_line(1)
	end

	function self:draw_shadow_line(n)
		local a=scalar
		local b=big_size/4
		local x=self.x+big_size/4
		local y=self.y+2*(big_size)
		draw_shadow_line(a,b,n,x,y)
	end

	return self
end
-->8
--skeleton

skeleton_crawl_speed=0.5*scalar
skeleton_float_speed=0.3*scalar
skeleton_crawl_distance=big_size*20
skeleton_crawl_frequency=50
skeleton_hover_frequency=100
skeleton_hover_amp=2
skeleton_hover_disp=3
rise_length=20
skeleton_near=3*big_size
skeleton_close=5*big_size

function skeleton_new(x0,y0)
	local self={
		type="skeleton",
		x=x0,
		y=y0,
		dx=0,
		dy=0,
		tt=0,
		hover_p=0,
		hover_y=0,
		turned=false,
		frame_head=9,
		frame_crawl_body=41,
		frame_float_body=25,
		x1=x0,
		x2=x0+big_size,
		y1=y0+big_size*2-scalar,
		y2=y0+big_size*2+scalar,
		state="bury",
		nrise=0,
	}

	function self:update()
		self.tt=inc_tt(self.tt)
		self:move()
		self:collision()
		self:animate()
	end

	function self:bury()
		return self.state=="bury"
	end

	function self:rise()
		return self.state=="rise"
	end

	function self:crawl()
		return self.state=="crawl"
	end

	function self:float()
		return self.state=="float"
	end

	function self:move()
		if self:bury() then
			self.dx,self.dy=0,0
		elseif self:crawl() then
			self:crawl_to_player()
		elseif self:float() then
			self:float_to_player()
		elseif self:rise() then
			self.dx,self.dy=0,0
		else
			assert(false)
		end
		self.x+=self.dx
		self.y+=self.dy
		if self.dx<0 then
			self.turned=true
		elseif self.dx>0 then
			self.turned=false
		end
		self:update_bounds()
	end

	function self:crawl_to_player()
		local a=skeleton_crawl_speed
		local angle=atan2(player.x-self.x,player.y-self.y)
		self.dx=cos(angle)*a
		self.dy=sin(angle)*a
	end

	function self:float_to_player()
		local a=skeleton_float_speed
		local angle=atan2(player.x-self.x,player.y-self.y)
		self.dx=cos(angle)*a
		self.dy=sin(angle)*a
	end

	function self:update_bounds()
		self.x1=self.x
		self.x2=self.x+big_size
		self.y1=self.y+big_size*2-scalar
		self.y2=self.y+big_size*2+scalar
	end

	function self:collision()
		local close=skeleton_close
		local near=skeleton_near
		self.dist=distance(self,player)
		if self:bury() then
			if self.dist>near then
				self.state="crawl"
			end
		elseif self:collide_with_player() then
			if not self:bury() then
				--player:die()
				self:die()
			end
		elseif self.dist<near then
			if self:crawl() then
				self.state="rise"
			end
			self.nrise=min(self.nrise+1,rise_length)
			if self.nrise==rise_length then
				if self:rise() then
					self.tt=0
				end
				self.state="float"
			end
		elseif self:float() and self.dist>close then
			self.state="rise"
		elseif self:rise() then
			self.nrise=max(0,self.nrise-2)
			if self.nrise==0 then
				self.state="crawl"
			end
		end
	end

	function self:collide_with_player()
		return collision(self,player)
	end

	function self:animate()
		self:animate_body()
	end

	function self:animate_body()
		local a=scalar
		local shf=skeleton_hover_frequency
		local sha=skeleton_hover_amp
		local shd=skeleton_hover_disp
		self.hover_p=cos(self.tt/shf)
		self.hover_y=a*self.hover_p*sha-a*shd
	end

	function self:draw()
		if self:bury() then
		elseif self:crawl() then
			self:draw_crawl_body()
			self:draw_crawl_head()
		elseif self:rise() then
			self:draw_rise_body()
			self:draw_rise_head()
		else
			self:draw_float_body()
			self:draw_float_head()
		end
	end

	function self:draw_shadow()
		if self:float() then
			self:draw_shadow_line(-1)
			self:draw_shadow_line(0)
			self:draw_shadow_line(1)
		end
	end

	function self:draw_shadow_line(n)
		local a=scalar
		local b=big_size/4
		local x=self.x+big_size/4
		local y=self.y+2*(big_size)
		draw_shadow_line(a,b,n,x,y)
	end

	function self:draw_float_head()
		local x=self.x
		local y=self.y+self.hover_y
		zspr(self.frame_head,x,y,self.turned)
	end

	function self:draw_crawl_head()
		local x=self.x
		local y=self.y+big_size
		local scf=skeleton_crawl_frequency
		x+=cos(self.tt/scf)*scalar
		zspr(self.frame_head,x,y,self.turned)
	end

	function self:draw_rise_head()
		local x=self.x
		local y=self.y+big_size
		local r=min(rise_length/2,self.nrise)
		local f=rise_length*4
		local d=sin(r/f)*big_size/2
		if self.turned then
			x-=d
			y+=d
		else
			x+=d
			y+=d
		end
		if self.nrise>r then
			local shd=-self.hover_y
			local rd=rise_length-self.nrise
			local rt=cos(rd/f*2)*shd
			y-=rt
		end
		zspr(self.frame_head,x,y,self.turned)
	end

	function self:draw_rise_body()
		local x=self.x
		local y=self.y+big_size+scalar*2
		if self.nrise>rise_length/2 then
			frame=self.frame_float_body
			if self.turned then
				x+=big_size/2-scalar
			else
				x-=big_size/2-scalar*2
			end
			y+=scalar*3
			local f=rise_length*4
			local shd=skeleton_hover_disp
			local rd=rise_length-self.nrise
			local rt=cos(rd/f*2)*shd
			y-=rt
		else
			frame=self.frame_crawl_body
			if self.turned then
				x+=big_size
			else
				x-=big_size
			end
			local scf=skeleton_crawl_frequency
			x-=cos(self.tt/scf)*scalar
		end
		zspr(frame,x,y,self.turned)
	end

	function self:draw_float_body()
		local x=self.x
		local y=self.y+self.hover_y+big_size
		zspr(self.frame_float_body,x,y,self.turned)
	end

	function self:draw_crawl_body()
		local x=self.x
		local y=self.y+big_size+scalar*2
		local frame
		frame=self.frame_crawl_body
		if self.turned then
			x+=big_size
		else
			x-=big_size
		end
		local scf=skeleton_crawl_frequency
		x-=cos(self.tt/scf)*scalar
		zspr(frame,x,y,self.turned)
	end

	function self:die()
		del(sprites,self)
		init_skeleton()
	end
	
	return self
end
-->8
--map

world={}

moon_x=96
moon_y=20
moon_r=16
num_stars=100
num_clouds=2
cloud_div=(128+32)/num_clouds
num_grave_cols=12
num_grave_rows=6

function world_init()
	local self={
		stars={},
		clouds={},
		graves={},
	}

	for j=0,num_grave_cols do
		for k=0,num_grave_rows-1 do
			local x=12*j*scalar
			local y=50+12*k*scalar
			local f=rnd({10,11,12,13})
			local d=rnd({26,27,28,29})
			if on_path(j,k) then
			elseif rnd(1)<0.3 then
			else
				add(self.graves,{
					f=f,
					x=x,
					y=y,
					d=d,
					open=rnd(1)<0.2,
					update=update_grave,
					draw=draw_grave,
					draw_shadow=draw_grave_shadow,
				})
			end
		end
	end

	foreach(self.graves,function(g)
		add(sprites,g)
	end)

	for i=1,num_clouds do
		local cx=rnd(cloud_div/num_clouds)
		local cdx=cloud_div*i-64+cx
		add(self.clouds, {
			x=cdx,
			y=rnd_cloud_y(),
			dx=rnd_cloud_dx(),
			--dx=rnd(1)+1,
			--dx=1,
			frame=70,
		})
	end

	for i=1,num_stars do
		local sx=flr(rnd(128))
		local sy=flr(rnd(60))
		local rx=abs(sx-moon_x)>(moon_r+2)
		local ry=abs(sy-moon_y)>(moon_r+2)
		if rx or ry then
			add(self.stars,{
				x=sx,
				y=sy,
			})
		end
	end
	
	function self:update()
		self:update_clouds()
	end
	
	function self:draw()
		--draw sky
		cls(1)

		--draw ground
		rectfill(0,64,128,128,2)

		self:draw_lantern_light()

		--draw moon
		circfill(moon_x,moon_y,moon_r,14)
		circfill(moon_x+5,moon_y-5,moon_r,1)

		self:draw_stars()
		self:draw_clouds()

		--self:draw_cemetary()
	end

	function self:draw_lantern_light()
		local x=player.x
		local y=player.y+big_size+player.ty/4
		local r=big_size*3-player.ty
		if player.turned then
			x-=big_size*3+1-player.ty
		else
			x+=big_size
		end
		clip(0,64,128,64)
		ovalfill(x,y,x+r,y+r/2,14)
		clip()
	end

	function self:update_clouds()
		foreach(self.clouds,update_cloud)
	end

	function self:draw_clouds()
		foreach(self.clouds,draw_cloud)
	end

	function self:draw_stars()
		foreach(self.stars,draw_star)
	end

	return self
end

path_cols={4}
path_rows={3}
function on_path(j,k)
	for x in all(path_cols) do
		if j==x then
			return true
		end
	end
	for x in all(path_rows) do
		if k==x then
			return true
		end
	end
	return false
end

function update_grave(g)
end
function draw_grave_shadow(g)
	local f
	if g.open then
		f=g.d+16
	else
		f=g.d
	end
	zspr(f,g.x,g.y+big_size*2)
end
function draw_grave(g)
	zspr(g.f,g.x,g.y+big_size)
end

function update_cloud(c)
	c.x+=c.dx
	if c.x>128 then
		c.x=-32
		c.y=rnd_cloud_y()
		c.dx=rnd_cloud_dx()
	end
end

function rnd_cloud_y()
	return flr(rnd(15))+4
end

function rnd_cloud_dx()
	return rnd(1)/4+0.25
end

function draw_cloud(c)
	bspr(c.frame,c.x,c.y,false,false)
end

function draw_star(s)
	pset(s.x,s.y,7)
end
__gfx__
00000000998888889988888899888888998899990000000099999999000000000000000099999999999999999995599999999999999999990000000000000000
000000009888aaaa9888aaaa9888aaaa9f8889990000000099999999000000000000000099999999955555999995599999555599999999990000000000000000
0070070088affff988affff988affff97ff889990000000099999999000000000000000099999999955555599555555995555559999999990000000000000000
0007700088ff0f0988ff0f0988ff0f097798a8990000000096666669000000000000000096666669950005599555555995000059999999990000000000000000
00077000aaf070f9aaf070f9aaf070f9798aaa890000000096606069000000000000000096606069955555599995599995555559995555990000000000000000
00700700aaff0fffaaff0fffaaff0fff998aaa890000000096666669000000000000000096666669955005599555555995555559955555590000000000000000
00000000aaeffff9aafffff9aafffff9998aaa890000000099696969000000000000000099696969955555599500005995555559950005590000000000000000
00000000aafeef99aafeef99aaffef99998888890000000099999999000000000000000099999999955555599555555995555559955555590000000000000000
0000000078ffff8978ffff8978ffff89999999990000000096666669999999990000000096666669999999999999999999999999999999990000000000000000
00000000787777897877778978777789999999990000000099969999999999960000000099969999999444449444449999444449999444490000000000000000
00000000f8888889f8888889f8888889999999990000000099666699999696960000000099666699444444444444444494444444994444440000000000000000
00000000988888899888888998888889999999990000000099969999996666660000000099969999444444444444444444444444444444440000000000000000
00000000988898899ff9988998889ff9999999990000000099666999999696960000000099666999444444494444444444444444444444440000000000000000
000000009ff99ff99aaa9ff99ff99aaa999999990000000099969999999996960000000099969999994444499444444994444444444444440000000000000000
000000009aaa9aaa99999aaa9aaa9999999999990000000099999999999999960000000099999999999999999999999999999999999999990000000000000000
00000000999999999999999999999999999999990000000099999999999999990000000099999999999999999999999999999999999999990000000000000000
00000000999999999999999999999999999999990000000000000000000000000000000099999999999444449444449999444449999444490000000000000000
00000000999999999999999999999999999999990000000000000000000000000000000099999996444400044400044494400044994400440000000000000000
00000000999777999997779999977799999777990000000000000000000000000000000099969696400000044000000444000004444000040000000000000000
00000000997777799977777999777779997777790000000000000000000000000000000099666666400000000000000440000004400000040000000000000000
00000000977777799777777997777779977777790000000000000000000000000000000099969696400000000000000000000000000000000000000000000000
00000000977070799707770997007009977070790000000000000000000000000000000099999696940000044000000440000000000000000000000000000000
00000000977070799770707997707079970777090000000000000000000000000000000099999996994444499444444994444444444444440000000000000000
00000000977777799777777997777779977777790000000000000000000000000000000099999999999999999999999999999999999999990000000000000000
00000000977777799777777997777779977777790000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000977777799777777997777779977777790000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000977797999779797997797979977979790000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000979799999779999999799999997999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999999999799999999999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999999999999999999999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999999999999999999999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999999999999999999999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000099999999999999999999999999999999000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000099999999999999999999999999999999000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000099999999995555559995555999999999000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000099999999556666665556666599999999000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000099999995666666666666666659999999000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000099999995666666666666666655559999000000000000000000000000000000000000000000000000
99999999999999999999995555999999000000000000000099999956666666666666666656665999000000000000000000000000000000000000000000000000
99999999999999999999556666559999000000000000000099999956666666666556666666666599000000000000000000000000000000000000000000000000
99999999555559995555555666659999000000000000000099999956666666666665666666666599000000000000000000000000000000000000000000000000
99999955666665556665666666665999000000000000000099999956666666666666666666666599000000000000000000000000000000000000000000000000
99999566666665656666666666665999000000000000000099999556666556666666666666666599000000000000000000000000000000000000000000000000
99999566666666666666666666665999000000000000000099995666665666666666666666655999000000000000000000000000000000000000000000000000
99995666666666666666666666655999000000000000000099995666665666666666666666659999000000000000000000000000000000000000000000000000
99995666666666666666666666655999000000000000000099956666666666666666666666659999000000000000000000000000000000000000000000000000
99995566666666666666666666555999000000000000000099956666666666666666555566659999000000000000000000000000000000000000000000000000
99955666666666666666666666665999000000000000000099956666666666666665666656659999000000000000000000000000000000000000000000000000
99956566666666666666666666665999000000000000000099955666666666666666666666555999000000000000000000000000000000000000000000000000
9956656d666666666666666666665999000000000000000099556666666666656666666665666599000000000000000000000000000000000000000000000000
99566665666666666666666666dd5999000000000000000099566666666666566666666666666659000000000000000000000000000000000000000000000000
99566666666666666666666666559999000000000000000095666666666666566666666666666d59000000000000000000000000000000000000000000000000
995d6666666666666666666666665599000000000000000095666556666666666666666ddd66dd59000000000000000000000000000000000000000000000000
995d6666666666666dddddd666666599000000000000000095d66665555666666666dddd5dddd599000000000000000000000000000000000000000000000000
995dd666666666dddd5dd5dd66666659000000000000000095dd6666666666666666d55595555999000000000000000000000000000000000000000000000000
9995d666666666d55555555d66666d590000000000000000995d6666666666666666d59999999999000000000000000000000000000000000000000000000000
9995ddd6666666ddd59995dd6666dd590000000000000000995ddd666dddd666666dd59999999999000000000000000000000000000000000000000000000000
999955ddd666ddd55999995dd66dd599000000000000000099955ddddd55dd6666dd599999999999000000000000000000000000000000000000000000000000
99999955ddddd55999999955dddd559900000000000000009999955555995dddddd5999999999999000000000000000000000000000000000000000000000000
99999999555559999999999955559999000000000000000099999999999995555559999999999999000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000099999999999999999999999999999999000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000099999999999999999999999999999999000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000099999999999999999999999999999999000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000099999999999999999999999999999999000000000000000000000000000000000000000000000000
