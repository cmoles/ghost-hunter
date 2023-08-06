pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main

sprites={}
cell_size=8
row_size=16
big_size=32
big_size=8
big_size=16
scalar=big_size/cell_size
function _init()
	_update=start_update
	_draw=start_draw
end

function start_update()
	if (btnp(🅾️)) then
		tt=0
		sprites={}

		player=player_init()
		add(sprites,player)

		add(sprites,ghost_init())
		add(sprites,skeleton_init(flr(rnd(40))+64,64))

		world=world_init()

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
	tt+=1
	if tt<0 then
		tt=0
	end
	update_sprites()
	sort_sprites()
end

function game_draw()
	palt(0,false)
	palt(13,true)
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

function update_sprites()
	for i=1,#sprites do
		sprites[i]:update()
	end
end

function draw_sprites()
	clip(0,64,128,64)
	for i=1,#sprites do
		sprites[i]:draw_shadow()
	end
	clip()
	for i=1,#sprites do
		sprites[i]:draw()
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

function zspr(frame,x,y,flip_x,flip_y)
	local sx=flr(frame%row_size)*cell_size
	local sy=flr(frame/row_size)*cell_size

	sspr(sx,sy,cell_size,cell_size,x,y,big_size,big_size,flip_x,flip_y)
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
-->8
--player

player={}
player_speed=1*scalar
friction=0.8
gravity=0.2*scalar
max_speed_x=1.5*scalar
max_speed_y=.75*scalar

function player_init()
	local x0,y0=64,64
	local self={
		x=x0,
		y=y0,
		dx=0,
		dy=0,
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
		y1=y0,
		y2=y0+big_size*2,
	}
	
	function self:update()
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
			local a=mid(.2,self.hold_jump/10,1)
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
		self:collision_map()
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
		self.y1=self.y
		self.y2=self.y+big_size*2
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
			if tt%4==0 then
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
			--self:draw_shadow_circle()
		end
	end
	function self:draw_shadow_circle()
		if self.ty<0 then
			local a=scalar
			local b=max(3,self.ty*a/self.boost)
			local x=self.x+big_size/2
			local y=self.y+big_size*2-a
			--circfill(x,y,abs(self.ty)*a,5)
			ovalfill(x-b,y-a,x+b,y+a,5)
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
near=10*scalar
close=20*scalar

function ghost_init()
	local x0=128-256*flr(rnd(2))
	local y0=flr(rnd(32))
	local self={
		x=x0,
		y=y0,
		dx=0,
		dy=0,
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
		self:move()
		self:animate()
	end

	function self:draw()
		self:draw_head()
		self:draw_body()
	end

	function self:move()
		if abs(player.x-self.x)<near and abs(player.y-self.y)<near then
			self.dx,self.dy=0,0
		else
			self:move_to_player()
		end
		self.x+=self.dx
		self.y+=self.dy
		if self.dx<0 then
			self.turned=true
		else
			self.turned=false
		end
		self:update_bounds()
	end

	function self:move_to_player()
		local a=ghost_speed
		if abs(player.x-self.x)<close and abs(player.y-self.y)<close then
			a=ghost_speed/2
		end
		local angle=atan2(player.x-self.x,player.y-self.y)
		self.dx=cos(angle)*a
		self.dy=sin(angle)*a
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
		if tt%4==0 then
			self.frame_body_index+=1
		end
		if self.frame_body_index>#self.frame_body then
			self.frame_body_index=1
		end
		local a=scalar
		self.hover_p=cos(tt/100)
		self.hover_y=a*self.hover_p*2-a*10
	end

	function self:draw_head()
		local x=self.x
		local y=self.y+self.hover_y
		zspr(self.frame_head,x,y,self.turned)
	end

	function self:get_frame_body()
		return self.frame_body[self.frame_body_index]
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

skeleton_speed=0.8*scalar

function skeleton_init(x0,y0)
	local self={
		x=x0,
		y=y0,
		dx=0,
		dy=0,
		hover_p=0,
		hover_y=0,
		turned=false,
		frame_head=6,
		frame_body=22,
		x1=x0,
		x2=x0+big_size,
		y1=y0,
		y2=y0+big_size*2,
	}

	function self:update()
		self:move()
		self:collision()
		self:animate()
	end

	function self:move()
		self:move_to_player()
		self.x+=self.dx
		self.y+=self.dy
		if self.dx<0 then
			self.turned=true
		else
			self.turned=false
		end
		self:update_bounds()
	end

	function self:move_to_player()
		local a=skeleton_speed
		local angle=atan2(player.x-self.x,player.y-self.y)
		self.dx=cos(angle)*a
		self.dy=sin(angle)*a
	end

	function self:update_bounds()
		self.x1=self.x
		self.x2=self.x+big_size
		self.y1=self.y
		self.y2=self.y+big_size*2
	end

	function self:collision()
		if self:collide_with_player() then
			--player:die()
			self:die()
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
		self.hover_p=cos(tt/100)
		self.hover_y=a*self.hover_p*2-a*3
	end

	function self:draw()
		self:draw_body()
		self:draw_head()
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

	function self:draw_head()
		local x=self.x
		local y=self.y+self.hover_y
		zspr(self.frame_head,x,y)
	end

	function self:draw_body()
		local x=self.x
		local y=self.y+self.hover_y+big_size
		zspr(self.frame_body,x,y)
	end

	function self:die()
		del(sprites,self)
	end
	
	return self
end
-->8
--map

world={}

function world_init()
	local self={}
	
	function self:update()
	end
	
	function self:draw()
		cls(1)
		--rectfill(0,64,128,128,3)
		--rectfill(0,64,128,128,14)
		rectfill(0,64,128,128,2)
		self:draw_lantern_light()
	end

	function self:draw_lantern_light()
		local x=player.x+big_size
		local y=player.y+big_size
		local r=big_size*3
		if player.turned then
			x-=big_size*4+1
		end
		clip(0,64,128,64)
		ovalfill(x,y,x+r,y+r/2,14)
		clip()
	end
	
	return self
end
__gfx__
00000000dd888888dd888888dd888888dd88dddd00000000dddddddd000000000000000000000000dddddddd0000000000000000000000000000000000000000
00000000d888aaaad888aaaad888aaaadf888ddd00000000dddddddd000000000000000000000000d55555dd0000000000000000000000000000000000000000
0070070088affffd88affffd88affffd7ff88ddd00000000dddddddd000000000000000000000000d555555d0000000000000000000000000000000000000000
0007700088ff0f0d88ff0f0d88ff0f0d77d8a8dd00000000d666666d000000000000000000000000d500055d0000000000000000000000000000000000000000
00077000aaf070fdaaf070fdaaf070fd7d8aaa8d00000000d660606d000000000000000000000000d555555d0000000000000000000000000000000000000000
00700700aaff0fffaaff0fffaaff0fffdd8aaa8d00000000d666666d000000000000000000000000d550055d0000000000000000000000000000000000000000
00000000aaeffffdaaeffffdaaeffffddd8aaa8d00000000dd6d6d6d000000000000000000000000d555555d0000000000000000000000000000000000000000
00000000aafeefddaafeefddaafeefdddd88888d00000000dddddddd000000000000000000000000d555555d0000000000000000000000000000000000000000
0000000078ffff8d78ffff8d78ffff8d0000000000000000d666666d000000000000000000000000d44d444d0000000000000000000000000000000000000000
000000007877778d7877778d7877778d0000000000000000ddd6dddd00000000000000000000000044d4444d0000000000000000000000000000000000000000
00000000f888888df888888df888888d0000000000000000dd6666dd000000000000000000000000444444d40000000000000000000000000000000000000000
00000000d888888dd888888dd888888d0000000000000000ddd6dddd000000000000000000000000444044440000000000000000000000000000000000000000
00000000d888d88ddffdd88dd888dffd0000000000000000dd666ddd00000000000000000000000044444d4d0000000000000000000000000000000000000000
00000000dffddffddaaadffddffddaaa0000000000000000ddd6dddd000000000000000000000000d4d4444d0000000000000000000000000000000000000000
00000000daaadaaadddddaaadaaadddd0000000000000000dddddddd0000000000000000000000004444404d0000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd0000000000000000dddddddd000000000000000000000000d444d44d0000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ddd777ddddd777ddddd777dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dd77777ddd77777ddd77777d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777777dd777777dd777777d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d770707dd770707dd770707d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d770707dd770707dd770707d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777777dd777777dd777777d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777777dd777777dd777777d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777777dd777777dd777777d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777d7ddd77d7d7dd77d7d7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d7d7ddddd77ddddddd7ddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ddddddddd7dddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
