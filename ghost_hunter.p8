pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main
debug=true
debug=false

sprites={}
cell_size=8
row_size=16
big_size=32
big_size=16
big_size=8
scalar=big_size/cell_size
function _init()
	if not debug then
		start_screen()
	else
		start_game()
	end
end

function start_game()
	tt=0
	sprites={}

	cemetary=cemetary_init()

	player=player_new()
	player:init()
	add(sprites,player)

	add(sprites,ghost_new())
	init_skeleton()

	_update=game_update
	_draw=game_draw
end

function start_screen()
	_update=start_update
	_draw=start_draw
end

function start_update()
	if (btnp(🅾️)) then
		start_game()
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
	cemetary:update()
end

function game_draw()
	palt(0,false)
	palt(9,true)
	cemetary:draw()
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
	local grave=rnd(cemetary.graves)
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
	if debug then
		foreach(sprites,function(sprite)
			sprite:draw_boundary()
		end)
	end
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
		self:get_direction_input()
		self:get_jump_input()
		self:get_dig_input()
	end

	function self:get_direction_input()
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

	end
	function self:get_jump_input()
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

	function self:get_dig_input()
		if btnp(🅾️) then
			cemetary:try_dig()
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

	function self:draw_boundary()
		local x1=self.x1
		local x2=self.x2
		local y1=self.y1
		local y2=self.y2
		local x3=self.behind.x1
		local x4=self.behind.x2
		local y3=self.behind.y1
		local y4=self.behind.y2
		rectfill(x1,y1,x2,y2,8)
		rectfill(x3,y3,x4,y4,10)
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
	local ghost={
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

	function ghost:update()
		ghost.tt=inc_tt(ghost.tt)
		ghost:move()
		ghost:animate()
	end

	function ghost:draw()
		ghost:draw_head()
		ghost:draw_body()
	end

	function ghost:move()
		ghost.dist=distance(ghost,player.behind)
		if ghost.dist<ghost_near then
			ghost.dx,ghost.dy=0,0
		else
			ghost:move_to_player()
		end
		ghost.x+=ghost.dx
		ghost.y+=ghost.dy
		if ghost.dx<0 then
			ghost.turned=true
		elseif ghost.dx>0 then
			ghost.turned=false
		end
		ghost:update_bounds()
	end

	function ghost:move_to_player()
		local a=ghost_speed
		if ghost.dist<ghost_near then
			a=ghost_speed/4
		elseif ghost.dist<ghost_close then
			a=ghost_speed/2
		end
		local p=player.behind
		local sx=(ghost.x1+ghost.x2)/2
		local sy=(ghost.y1+ghost.y2)/2
		local angle=atan2(p.x-sx,p.y-sy)
		ghost.dx=cos(angle)*a
		ghost.dy=sin(angle)*a/2
	end

	function ghost:update_bounds()
		ghost.x1=ghost.x
		ghost.x2=ghost.x+big_size
		ghost.y1=ghost.y
		ghost.y2=ghost.y+big_size*2
	end

	function ghost:animate()
		ghost:animate_body()
	end

	function ghost:animate_body()
		if ghost.tt%4==0 then
			ghost.frame_body_index+=1
		end
		if ghost.frame_body_index>#ghost.frame_body then
			ghost.frame_body_index=1
		end
		local a=scalar
		ghost.hover_p=cos(ghost.tt*ghost_float_freq)
		ghost.hover_y=a*ghost.hover_p*ghost_float_amp-a*ghost_float_disp
	end

	function ghost:draw_head()
		local x=ghost.x
		local y=ghost.y+ghost.hover_y
		zspr(ghost.frame_head,x,y,ghost.turned)
	end

	function ghost:get_frame_body()
		return ghost.frame_body[ghost.frame_body_index]
	end

	function ghost:draw_float_body()
		local x=ghost.x
		local y=ghost.y+ghost.hover_y+big_size
		zspr(ghost:get_frame_body(),x,y,ghost.turned)
	end

	function ghost:draw_body()
		local x=ghost.x
		local y=ghost.y+ghost.hover_y+big_size
		zspr(ghost:get_frame_body(),x,y,ghost.turned)
	end

	function ghost:draw_boundary()
		local x1=self.x1
		local x2=self.x2
		local y1=self.y1
		local y2=self.y2
		rectfill(x1,y1,x2,y2,8)
	end

	function ghost:draw_shadow()
		ghost:draw_shadow_line(-1)
		ghost:draw_shadow_line(0)
		ghost:draw_shadow_line(1)
	end

	function ghost:draw_shadow_line(n)
		local a=scalar
		local b=big_size/4
		local x=ghost.x+big_size/4
		local y=ghost.y+2*(big_size)
		draw_shadow_line(a,b,n,x,y)
	end

	return ghost
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
	local skeleton={
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

	function skeleton:update()
		skeleton.tt=inc_tt(skeleton.tt)
		skeleton:move()
		skeleton:collision()
		skeleton:animate()
	end

	function skeleton:bury()
		return skeleton.state=="bury"
	end

	function skeleton:rise()
		return skeleton.state=="rise"
	end

	function skeleton:crawl()
		return skeleton.state=="crawl"
	end

	function skeleton:float()
		return skeleton.state=="float"
	end

	function skeleton:move()
		if skeleton:bury() then
			skeleton.dx,skeleton.dy=0,0
		elseif skeleton:crawl() then
			skeleton:crawl_to_player()
		elseif skeleton:float() then
			skeleton:float_to_player()
		elseif skeleton:rise() then
			skeleton.dx,skeleton.dy=0,0
		else
			assert(false)
		end
		skeleton.x+=skeleton.dx
		skeleton.y+=skeleton.dy
		if skeleton.dx<0 then
			skeleton.turned=true
		elseif skeleton.dx>0 then
			skeleton.turned=false
		end
		skeleton:update_bounds()
	end

	function skeleton:crawl_to_player()
		local a=skeleton_crawl_speed
		local angle=atan2(player.x-skeleton.x,player.y-skeleton.y)
		skeleton.dx=cos(angle)*a
		skeleton.dy=sin(angle)*a
	end

	function skeleton:float_to_player()
		local a=skeleton_float_speed
		local angle=atan2(player.x-skeleton.x,player.y-skeleton.y)
		skeleton.dx=cos(angle)*a
		skeleton.dy=sin(angle)*a
	end

	function skeleton:update_bounds()
		skeleton.x1=skeleton.x
		skeleton.x2=skeleton.x+big_size
		skeleton.y1=skeleton.y+big_size*2-scalar
		skeleton.y2=skeleton.y+big_size*2+scalar
	end

	function skeleton:collision()
		local close=skeleton_close
		local near=skeleton_near
		skeleton.dist=distance(skeleton,player)
		if skeleton:bury() then
			if skeleton.dist>near then
				skeleton.state="crawl"
			end
		elseif skeleton:collide_with_player() then
			if not skeleton:bury() then
				--player:die()
				skeleton:die()
			end
		elseif skeleton.dist<near then
			if skeleton:crawl() then
				skeleton.state="rise"
			end
			skeleton.nrise=min(skeleton.nrise+1,rise_length)
			if skeleton.nrise==rise_length then
				if skeleton:rise() then
					skeleton.tt=0
				end
				skeleton.state="float"
			end
		elseif skeleton:float() and skeleton.dist>close then
			skeleton.state="rise"
		elseif skeleton:rise() then
			skeleton.nrise=max(0,skeleton.nrise-2)
			if skeleton.nrise==0 then
				skeleton.state="crawl"
			end
		end
	end

	function skeleton:collide_with_player()
		return collision(skeleton,player)
	end

	function skeleton:animate()
		skeleton:animate_body()
	end

	function skeleton:animate_body()
		local a=scalar
		local shf=skeleton_hover_frequency
		local sha=skeleton_hover_amp
		local shd=skeleton_hover_disp
		skeleton.hover_p=cos(skeleton.tt/shf)
		skeleton.hover_y=a*skeleton.hover_p*sha-a*shd
	end

	function skeleton:draw()
		if skeleton:bury() then
		elseif skeleton:crawl() then
			skeleton:draw_crawl_body()
			skeleton:draw_crawl_head()
		elseif skeleton:rise() then
			skeleton:draw_rise_body()
			skeleton:draw_rise_head()
		else
			skeleton:draw_float_body()
			skeleton:draw_float_head()
		end
	end

	function skeleton:draw_boundary()
		local x1=self.x1
		local x2=self.x2
		local y1=self.y1
		local y2=self.y2
		rectfill(x1,y1,x2,y2,8)
	end

	function skeleton:draw_shadow()
		if skeleton:float() then
			skeleton:draw_shadow_line(-1)
			skeleton:draw_shadow_line(0)
			skeleton:draw_shadow_line(1)
		end
	end

	function skeleton:draw_shadow_line(n)
		local a=scalar
		local b=big_size/4
		local x=skeleton.x+big_size/4
		local y=skeleton.y+2*(big_size)
		draw_shadow_line(a,b,n,x,y)
	end

	function skeleton:draw_float_head()
		local x=skeleton.x
		local y=skeleton.y+skeleton.hover_y
		zspr(skeleton.frame_head,x,y,skeleton.turned)
	end

	function skeleton:draw_crawl_head()
		local x=skeleton.x
		local y=skeleton.y+big_size
		local scf=skeleton_crawl_frequency
		x+=cos(skeleton.tt/scf)*scalar
		zspr(skeleton.frame_head,x,y,skeleton.turned)
	end

	function skeleton:draw_rise_head()
		local x=skeleton.x
		local y=skeleton.y+big_size
		local r=min(rise_length/2,skeleton.nrise)
		local f=rise_length*4
		local d=sin(r/f)*big_size/2
		if skeleton.turned then
			x-=d
			y+=d
		else
			x+=d
			y+=d
		end
		if skeleton.nrise>r then
			local shd=-skeleton.hover_y
			local rd=rise_length-skeleton.nrise
			local rt=cos(rd/f*2)*shd
			y-=rt
		end
		zspr(skeleton.frame_head,x,y,skeleton.turned)
	end

	function skeleton:draw_rise_body()
		local x=skeleton.x
		local y=skeleton.y+big_size+scalar*2
		if skeleton.nrise>rise_length/2 then
			frame=skeleton.frame_float_body
			if skeleton.turned then
				x+=big_size/2-scalar
			else
				x-=big_size/2-scalar*2
			end
			y+=scalar*3
			local f=rise_length*4
			local shd=skeleton_hover_disp
			local rd=rise_length-skeleton.nrise
			local rt=cos(rd/f*2)*shd
			y-=rt
		else
			frame=skeleton.frame_crawl_body
			if skeleton.turned then
				x+=big_size
			else
				x-=big_size
			end
			local scf=skeleton_crawl_frequency
			x-=cos(skeleton.tt/scf)*scalar
		end
		zspr(frame,x,y,skeleton.turned)
	end

	function skeleton:draw_float_body()
		local x=skeleton.x
		local y=skeleton.y+skeleton.hover_y+big_size
		zspr(skeleton.frame_float_body,x,y,skeleton.turned)
	end

	function skeleton:draw_crawl_body()
		local x=skeleton.x
		local y=skeleton.y+big_size+scalar*2
		local frame
		frame=skeleton.frame_crawl_body
		if skeleton.turned then
			x+=big_size
		else
			x-=big_size
		end
		local scf=skeleton_crawl_frequency
		x-=cos(skeleton.tt/scf)*scalar
		zspr(frame,x,y,skeleton.turned)
	end

	function skeleton:die()
		del(sprites,skeleton)
		init_skeleton()
	end
	
	return skeleton
end
-->8
--map

cemetary={}

moon_x=96
moon_y=20
moon_r=16
num_stars=100
num_clouds=2
cloud_div=(128+32)/num_clouds
num_grave_cols=12
num_grave_rows=6

function cemetary_init()
	local world={
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
				add(world.graves,{
					f=f,
					x=x,
					y=y,
					d=d,
					open=rnd(1)<0.2,
					update=update_grave,
					draw=draw_grave,
					draw_boundary=draw_grave_boundary,
					draw_shadow=draw_grave_shadow,
				})
			end
		end
	end

	foreach(world.graves,function(g)
		add(sprites,g)
	end)

	for i=1,num_clouds do
		local cx=rnd(cloud_div/num_clouds)
		local cdx=cloud_div*i-64+cx
		add(world.clouds, {
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
			add(world.stars,{
				x=sx,
				y=sy,
			})
		end
	end

	function world:try_dig()
		local x=player.x
		local y=player.y
		local w=big_size
		local h=big_size
		local d=big_size/2
		local cx=x+d
		local cy=y+d
		local g=world:get_grave(cx,cy)
		if g then
			if g.open then
				g.open=false
				sfx(1)
			else
				g.open=true
				sfx(2)
			end
		end
	end

	function world:get_grave(cx,cy)
		local g=nil
		foreach(world.graves,function(grave)
			local x=grave.x
			local y=grave.y
			local w=grave.d
			local h=grave.d
			if cx>x and cx<x+w and cy>y and cy<y+h then
				g=grave
			end
		end)
		return g
	end
	
	function world:update()
		world:update_clouds()
	end
	
	function world:draw()
		--draw sky
		cls(1)

		--draw ground
		rectfill(0,64,128,128,2)

		world:draw_lantern_light()

		--draw moon
		circfill(moon_x,moon_y,moon_r,14)
		circfill(moon_x+5,moon_y-5,moon_r,1)

		world:draw_stars()
		world:draw_clouds()

		--world:draw_cemetary()
	end

	function world:draw_lantern_light()
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

	function world:update_clouds()
		foreach(world.clouds,update_cloud)
	end

	function world:draw_clouds()
		foreach(world.clouds,draw_cloud)
	end

	function world:draw_stars()
		foreach(world.stars,draw_star)
	end

	return world
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

function draw_grave_boundary(g)
	local x1=g.x1
	local x2=g.x2
	local y1=g.y1
	local y2=g.y2
	rectfill(x1,y1,x2,y2,8)
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
__sfx__
00010000076500d65014650246501d650156500c65007650066500265000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001e65011650096500765006650056500565005650056500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000076500d65014650246501d650156500c65007650066500265000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
