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

		player=player_init()
		add(sprites,player)

		add(sprites,ghost_init())
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
	local grave=world.graves[1]
	add(sprites,skeleton_init(grave.x,grave.y))
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
player_speed=1*scalar
friction=0.8
gravity=0.2*scalar
max_speed_x=1.5*scalar
max_speed_y=.85*scalar

function player_init()
	local x0,y0=64,64
	local self={
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
		x1=x0,
		x2=x0+big_size,
		y1=y0+big_size*2-scalar,
		y2=y0+big_size*2+scalar,
	}
	
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
	end

	function self:update_bounds()
		self.x1=self.x
		self.x2=self.x+big_size
		self.y1=self.y+big_size*2-scalar
		self.y2=self.y+big_size*2+scalar
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
near=2*big_size
close=5*big_size

function ghost_init()
	local x0=128-256*flr(rnd(2))
	local y0=flr(rnd(32))
	local self={
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
		self.dist=distance(self,player)
		if self.dist<near then
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
		if self.dist<near then
			a=ghost_speed/4
		elseif self.dist<close then
			a=ghost_speed/2
		end
		local px=near
		local py=player.y+big_size
		if player.turned then
			px=player.x+big_size
		else
			px=player.x
		end
		local angle=atan2(player.x-self.x,player.y-self.y)
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
rise_length=20

function skeleton_init(x0,y0)
	local self={
		x=x0,
		y=y0,
		dx=0,
		dy=0,
		tt=0,
		hover_p=0,
		hover_y=0,
		turned=false,
		frame_head=6,
		frame_crawl_body=23,
		frame_float_body=22,
		x1=x0,
		x2=x0+big_size,
		y1=y0+big_size*2-scalar,
		y2=y0+big_size*2+scalar,
		buried=true,
		crawl=true,
		rise=0,
	}

	function self:update()
		self.tt=inc_tt(self.tt)
		self:move()
		self:collision()
		self:animate()
	end

	function self:move()
		if self.buried then
			self.dx,self.dy=0,0
		elseif not self.crawl then
			self:float_to_player()
		elseif self.rise<=0 then
			self:crawl_to_player()
		else
			self.dx,self.dy=0,0
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
		self.dist=distance(self,player)
		if self.buried then
			if self.dist>close then
				self.buried=false
			end
		elseif self:collide_with_player() then
			if not self.buried then
				--player:die()
				self:die()
			end
		elseif self.dist<near then
			self.rise=min(self.rise+1,rise_length)
			if self.rise==rise_length then
				self.crawl=false
			else
				self.crawl=true
			end
		elseif self.dist>close then
			self.crawl=true
			self.rise=max(0,self.rise-2)
		end
	end

	function self:collide_with_player()
		return collision(self,player)
	end

	function self:near_player()
		return distance(self,player)<near
	end

	function self:animate()
		self:animate_body()
	end

	function self:animate_body()
		local a=scalar
		local shf=skeleton_hover_frequency
		self.hover_p=cos(self.tt/shf)
		self.hover_y=a*self.hover_p*2-a*3
		self.hover_y=a*self.hover_p*2-a*3
	end

	function self:draw()
		if self.buried then
		elseif self.crawl then
			self:draw_crawl_body()
			self:draw_crawl_head()
		else
			self:draw_float_body()
			self:draw_float_head()
		end
	end

	function self:draw_shadow()
		if self.buried then
		elseif self.crawl then
		else
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
		if self.rise>0 then
			local r=min(rise_length/2,self.rise)
			local f=rise_length*4
			local d=sin(r/f)*big_size/2
			if self.turned then
				x-=d
				y+=d
			else
				x+=d
				y+=d
			end
		else
			local scf=skeleton_crawl_frequency
			x+=cos(self.tt/scf)*scalar
		end
		zspr(self.frame_head,x,y,self.turned)
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
		if self.rise>rise_length/2 then
			frame=self.frame_float_body
			if self.turned then
				x+=big_size/2-scalar
			else
				x-=big_size/2-scalar*2
			end
			y+=scalar*3
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

function world_init()
	local self={
		stars={},
		clouds={},
		graves={
			{
				x=flr(rnd(32))+64,
				y=flr(rnd(32))+64,
			}
		},
	}

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

		self:draw_cemetary()
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

	function self:draw_cemetary()
		foreach(self.graves,draw_grave)
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

function draw_grave(g)
	local x=g.x
	local y=g.y
	zspr(10,x,y)
	zspr(26,x,y+big_size)
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
00000000998888889988888899888888998899990000000099999999000000000000000000000000999999990000000000000000000000000000000000000000
000000009888aaaa9888aaaa9888aaaa9f8889990000000099999999000000000000000000000000955555990000000000000000000000000000000000000000
0070070088affff988affff988affff97ff889990000000099999999000000000000000000000000955555590000000000000000000000000000000000000000
0007700088ff0f0988ff0f0988ff0f097798a8990000000096666669000000000000000000000000950005590000000000000000000000000000000000000000
00077000aaf070f9aaf070f9aaf070f9798aaa890000000096606069000000000000000000000000955555590000000000000000000000000000000000000000
00700700aaff0fffaaff0fffaaff0fff998aaa890000000096666669000000000000000000000000955005590000000000000000000000000000000000000000
00000000aaeffff9aaeffff9aaeffff9998aaa890000000099696969000000000000000000000000955555590000000000000000000000000000000000000000
00000000aafeef99aafeef99aafeef99998888890000000099999999000000000000000000000000955555590000000000000000000000000000000000000000
0000000078ffff8978ffff8978ffff89999999990000000096666669999999990000000000000000944944490000000000000000000000000000000000000000
00000000787777897877778978777789999999990000000099969999999999960000000000000000449444490000000000000000000000000000000000000000
00000000f8888889f8888889f8888889999999990000000099666699999696960000000000000000444444940000000000000000000000000000000000000000
00000000988888899888888998888889999999990000000099969999996666660000000000000000444044440000000000000000000000000000000000000000
00000000988898899ff9988998889ff9999999990000000099666999999696960000000000000000444449490000000000000000000000000000000000000000
000000009ff99ff99aaa9ff99ff99aaa999999990000000099969999999996960000000000000000949444490000000000000000000000000000000000000000
000000009aaa9aaa99999aaa9aaa9999999999990000000099999999999999960000000000000000444440490000000000000000000000000000000000000000
00000000999999999999999999999999999999990000000099999999999999990000000000000000944494490000000000000000000000000000000000000000
00000000999999999999999999999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999999999999999999999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999777999997779999977799999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000997777799977777999777779999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000977777799777777997777779999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000977070799770707997707079999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000977070799770707997707079999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000977777799777777997777779999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000977777799777777997777779999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000977777799777777997777779999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000977797999779797997797979999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000979799999779999999799999999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
