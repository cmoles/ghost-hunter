pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main
debug=true
debug=false
debug_bounds=false
--debug_bounds=true
debug_select=false
--debug_select=true
debug_print_ghost_num=false
--debug_print_ghost_num=true

level=1

sprites={}
cell_size=8
row_size=16
big_size=8
big_size=32
big_size=16
start_ghosts=1
scalar=big_size/cell_size
function _init()
	ready_game=true
	if not debug then
		start_screen()
	else
		start_game()
	end
end

function start_game()
	tt=0
	sprites={}

	local zoom_list={32,16,8}
	local zoom=zoom_list[level]

	cemetary=cemetary_init()
	cemetary:zoom_init(zoom)
	cemetary:generate_graves()

	player=player_new()
	player:init()
	add(sprites,player)

	local n=start_ghosts

	for i=1,n do
		local start_pt={x=rnd(64)+32,y=rnd(64)+32}
		init_ghost(start_pt)
	end

	_update=game_update
	_draw=game_draw
end

function start_screen()
	_update=start_update
	_draw=start_draw
end

ptt=0
function start_update()
	ptt=inc_tt(ptt)
	if btnp(🅾️) then
		ready_game=false
		_update=level_update
		_draw=level_draw
	end
end

function start_draw()
	camera()
	cls()
	print_title()
	local message="press 🅾️ to start"
	print(message,64-(#message*8)/4-2,64,7)
end

function print_title()
	local title="ghost hunter"
	local x0=64-(#title*8)/4
	local y0=32
	local dx=cos(ptt/10)*4
	local dy=sin(ptt/10)*4
	local w=#title
	local h=0
	print(title,x0,y0,10)
	clip(x0+dx+4,y0+dy,x0+dx-2,y0+dy-1)
	print(title,x0,y0,8)
	clip()
end

function game_update()
	tt=inc_tt(tt)
	update_sprites()
	sort_sprites()
	cemetary:update()
end

function game_draw()
	palt(0,false)
	palt(1,true)
	cemetary:draw()
	draw_sprites()
	camera()
	if debug_print_ghost_num then
		print(#ghosts,0,0,8)
		--print(player.y2,0,0,8)
		--print(cemetary.height+horizon,0,8,8)
	end
	camera(camx,camy)
end

function level_update()
	if ready_game and btn(🅾️) then
		ready_game=false
		start_game()
	elseif not ready_game and not btn(🅾️) then
		ready_game=true
	end
end

function level_draw()
	camera()
	cls()
	local message="level "..level
	print(message,64-(#message*8)/4,64,7)
end

function over_update()
	if (btnp(🅾️)) then
		_update=start_update
		_draw=start_draw
	end
end

function over_draw()
	camera()
	cls()
	local message="you win"
	print(message,64-(#message*8)/4,64,7)
end

function update_camera(px1,py1,px2,py2)
	local px=(px1+px2)/2
	local py=(py1+py2)/2-big_size
	--camx=px-window_width/2
	--camy=py-window_height/2
	camx=mid(0,px-screen_width/2,cemetary.width-screen_width)
	camy=mid(0,py-screen_height/2,cemetary.height-screen_height+horizon)
end

function clip_ground()
	local h1=max(0,horizon-camy)
	local h2=screen_height-h1
	clip(0,h1,screen_width,h2)
end

function init_ghost(grave)
	local ghost=ghost_new(grave.x,grave.y,#ghosts)
	--add(ghosts,ghost)
	add(sprites,ghost)
end

function init_skeleton(grave)
	local skeleton=skeleton_new(grave.x,grave.y)
	add(enemies,skeleton)
	add(sprites,skeleton)
end

function update_sprites()
	foreach(sprites,function(sprite)
		sprite:update()
	end)
end

function draw_sprites()
	clip_ground()
	foreach(sprites,function(sprite)
		sprite:draw_shadow()
	end)
	clip()
	foreach(sprites,function(sprite)
		sprite:draw()
	end)
	if debug and debug_bounds then
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
	local dd=dx*dx+dy*dy
	if dd>0 then
		return sqrt(dd)
	else
		return abs(dx)+abs(dy)
	end
end

function zspr(frame,x,y,flip_x,flip_y)
	local sx=flr(frame%row_size)*cell_size
	local sy=flr(frame/row_size)*cell_size

	sspr(sx,sy,cell_size,cell_size,x,y,big_size,big_size,flip_x,flip_y)
end

function bspr(frame,x,y,flip_x,flip_y)
	local sx=flr(frame%row_size)*cell_size
	local sy=flr(frame/row_size)*cell_size

	sspr(sx,sy,cell_size*4,cell_size*4,x,y,big_size*4,big_size*4,flip_x,flip_y)
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
player_max_speed=1.5*scalar
y_scalar=.5*scalar
begin_cool_down=10
bound_width=4*scalar
bound_height=2*scalar

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
		frame_shovel_top_idle=6,
		frame_shovel_bottom_idle=22,
		frame_shovel_top_ready=55,
		frame_shovel_bottom_ready=54,
		boost=-1.7*scalar,
		dz=0,
		sz=0,
		hold_jump=0,
		hold_light=0,
		cool_down_dig=0,
		cool_down_cmd=0,
		state="idle",
		surface=0,
		emote=0,
	}

	function self:init()
		self:update_bounds()
		self:update_queue()
		self:update_dig_target()
		self:update_cmd_target()
		update_camera(self.x1,self.y1,self.x2,self.y2)
	end
	
	function self:update()
		self.tt=inc_tt(self.tt)
		self:get_input()
		self:limit_speed()
		self:apply_gravity()
		self:collision()
		self:move()
		self:animate()
	end

	function self:idle()
		return self.state=="idle"
	end

	function self:jump()
		return self.state=="jump"
	end

	function self:crouch()
		return self.state=="crouch"
	end

	function self:dig()
		return self.state=="dig"
	end

	function self:ready()
		return self:idle() or self:crouch()
	end

	function self:focus()
		return self:crouch() or self:jump()
	end

	function self:lock()
		return self:slow() or self:jump() or btn(❎)
	end

	function self:slow()
		return self:crouch() or self:dig()
	end
	
	function self:draw()
		self:draw_lantern()
		self:draw_body()
		self:draw_head()
		self:draw_shovel()
	end

	function self:get_input()
		self.cool_down_dig=max(0,self.cool_down_dig-1)
		self.cool_down_cmd=max(0,self.cool_down_cmd-1)
		self.emote=max(0,self.emote-1)
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
			if not self:lock() then
				self.turned=true
			end
		end
		if btn(➡️) then
			self.dx+=speed
			if not self:lock() then
				self.turned=false
			end
		end
		if btn(⬆️) then
			self.dy-=speed
		end
		if btn(⬇️) then
			self.dy+=speed
		end

	end
	function self:get_jump_input()
		if not self:jump() then
			if self:ready() and btn(❎) then
				self.state="crouch"
				self.hold_jump+=1
				self.hold_light=min(10,self.hold_jump+1)
			elseif self.hold_jump>0 then
				local a=mid(.5,self.hold_jump/5,1.2)
				self.dz=a*self.boost
				self.hold_jump=0
				self.state="jump"
			end
		end

		if self:focus() and btnp(🅾️) then
			if self.cool_down_cmd==0 then
				self.cool_down_cmd=begin_cool_down
				ghosts_command()
			end
		end

		if self:jump() then
			self.hold_light=max(0,self.hold_light-1)
		end
	end

	function self:get_dig_input()
		if btn(🅾️) then
			if not ready_game then
				return
			end
		elseif not ready_game then
			ready_game=true
		end
		if self:idle() and btn(🅾️) then
			self.state="dig"
		elseif self:dig() and not btn(🅾️) then
			self.state="idle"
		end

		if self:dig() and btnp(❎) then
			if self.cool_down_dig==0 then
				self.cool_down_dig=begin_cool_down
				cemetary:try_dig()
			end
		end
	end

	function self:limit_speed()
		local mx=player_max_speed
		local my=player_max_speed*y_scalar
		if self:slow() then
			mx=player_speed
			my=player_speed
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

	function self:apply_gravity()
		if self.sz<self.surface then
			--print(self.surface)
			--assert(self.surface==0)
			self.dz+=gravity
		end
	end

	function self:collision()
		self:collision_floor()
		self:collision_sides()
		self:collision_map()
		self:collision_sprites()
	end

	function self:collision_floor()
		if self.dz>0 and self.sz>self.surface then
			self:land(self.surface)
		end
	end

	function self:collision_sides()
		local x1=self.x1+self.dx
		local x2=self.x2+self.dx
		local y1=self.y1+self.dy
		local y2=self.y2+self.dy
		if x1<0 and self.dx<0 then
			self.dx=0
		end
	    if x2>cemetary.width and self.dx>0 then
			self.dx=0
		end
		if y1<horizon and self.dy<0 then
			self.dy=0
		end
		if y2>cemetary.height+horizon and self.dy>0 then
			self.dy=0
		end
	end

	function self:land(surface)
		self.surface=surface
		self.sz=surface
		self.dz=0
		self.state="idle"
	end

	function self:get_move_boundary(dx,dy)
		return {
			x1=self.x1+dx,
			y1=self.y1+dy,
			x2=self.x2+dx,
			y2=self.y2+dy
		}
	end

	function self:collision_map()
		local dx,dy=self.dx,self.dy
		local b1=self:get_move_boundary(0,dy)
		local c1=cemetary:collision(b1)
		if c1<self.sz then
			dy=0
		end
		local b2=self:get_move_boundary(dx,dy)
		local c2=cemetary:collision(b2)
		if c2<self.sz then
			dx=0
		end
		local b3=self:get_move_boundary(dx,dy)
		local c3=cemetary:collision(b3)
		if c3<self.sz then
			self:land(c3)
		else
			self.dx,self.dy=dx,dy
			self.surface=c3
		end
	end

	function self:collision_sprites()
		for sprite in all(sprites) do
			if sprite.type=='ghost' then
				self:collect_ghost(sprite)
			end
		end
	end

	function self:collect_ghost(ghost)
		if not (ghost:lost() or ghost:scatter()) then
			return
		end
		if collision(self,ghost) then
			ghost:recall_to_player()
		end
	end

	function self:move()
		self.x+=self.dx
		self.y+=self.dy
		self.sz+=self.dz
		self:update_bounds()
		self:update_queue()
		self:update_dig_target()
		self:update_cmd_target()
		update_camera(self.x1,self.y1,self.x2,self.y2)
	end

	function self:update_bounds()
		local x1=self.x
		local y1=self.y+big_size
		local x2=self.x+big_size
		local y2=self.y+2*big_size
		local w=(x2+x1)/2
		local h=(y2+y1)/2
		self.x1=w-bound_width/2
		self.y1=h+bound_height
		self.x2=w+bound_width/2
		self.y2=h+bound_height+scalar
	end

	function self:update_queue()
		local m=#ghosts
		if self.turned then
			self.queue={
				x1=self.x1+big_size*m/4+big_size,
				x2=self.x2+big_size*m/4+big_size,
				y1=self.y1-big_size,
				y2=self.y2-big_size,
			}
		else
			self.queue={
				x1=self.x1-big_size*m/4-big_size,
				x2=self.x2-big_size*m/4-big_size,
				y1=self.y1-big_size,
				y2=self.y2-big_size,
			}
		end
	end

	function self:get_rotation(n)
		local a=1
		local m=#ghosts
		local x1=self.queue.x1
		local y1=self.queue.y1
		local x2=self.queue.x2
		local y2=self.queue.y2
		local f=1/(m)

		local b=60/m*2
		local c=.15

		local dx,dy,angle
		if not self.turned then
			a=-1*big_size*sqrt(m)/2
			dx=cos(n*f+tt/b*f)
			dy=sin(n*f+tt/b*f)
			angle=atan2(-dx,-dy)
			angle+=c
		else
			a=big_size*sqrt(m)/2
			dx=cos(n*f-tt/b*f)
			dy=sin(n*f-tt/b*f)
			angle=atan2(dx,dy)
			angle+=(.5-c)
		end
		angle=angle%1
		local selected=angle<1/m
		if selected then
			ghost_selected=n+1
		end
		return {
			x1=x1+a*dx,
			x2=x2+a*dx,
			y1=y1+a*dy,
			y2=y2+a*dy,
			selected=selected,
		}
	end

	function self:update_dig_target()
		if self.turned then
			self.dig_target={
				x1=self.x1-big_size/2-scalar,
				x2=self.x2-big_size-scalar,
				y1=self.y1,
				y2=self.y2,
			}
		else
			self.dig_target={
				x1=self.x1+big_size,
				x2=self.x2+big_size/2,
				y1=self.y1,
				y2=self.y2,
			}
		end
	end

	function self:update_cmd_target()
		local b=player.hold_light
		local x=player.x
		local y=player.y+big_size+player.sz/4-2*scalar
		local r=big_size*4-player.sz
		if player.turned then
			x-=big_size*4-player.sz+b+scalar
		else
			x+=big_size+b
		end
		self.cmd_target={
			x1=x,
			y1=y,
			x2=x+r,
			y2=y+r/2,
		}
	end

	function self:animate()
		self:animate_body()
	end

	function self:animate_body()
		if self:jump() then
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
		local y=self.y+self.sz
		if self.hold_jump>0 or self.cool_down_dig>begin_cool_down/2 then
			y+=1*scalar
		end
		if self.emote>0 then
			zspr(self.frame_head+1,self.x,y,self.turned)
		else
			zspr(self.frame_head,self.x,y,self.turned)
		end
	end

	function self:get_frame_body()
		if self.dx==0 and self.dy==0 then
			return self.frame_body_idle
		else
			return self.frame_body_walk[self.frame_body_walk_index]
		end
	end

	function self:draw_body()
		local y=self.y+self.sz
		zspr(self:get_frame_body(),self.x,y+big_size,self.turned)
	end

	function self:draw_lantern()
		if self:dig() then return end
		local x=self.x
		local y=self.y+self.sz+big_size/2+scalar
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

	function self:draw_shovel()
		if not self:dig() then
			self:draw_shovel_idle()
		else
			self:draw_shovel_ready()
		end
	end

	function self:draw_shovel_idle()
		local x=self.x
		local y=self.y+self.sz-3*scalar
		local a1=self.turned and self.cool_down_cmd==0
		local b1=not self.turned and self.cool_down_cmd>0
		local a2=self.turned and self.cool_down_cmd>0
		local b2=not self.turned and self.cool_down_cmd==0
		local turned=not(a2 or b2)
		if a1 or b1 then
			x+=big_size-3*scalar
		else
			x-=big_size-3*scalar
		end
		zspr(self.frame_shovel_top_idle,x,y,turned)
		zspr(self.frame_shovel_bottom_idle,x,y+big_size,turned)
	end

	function self:draw_shovel_ready()
		local x=self.x
		local x2=self.x
		local y1=self.y+big_size+self.sz
		if self.turned then
			x+=big_size-6*scalar
			x2+=-6*scalar
		else
			x-=big_size-6*scalar
			x2-=-6*scalar
		end
		if self.hold_jump>0 then
			y1+=1*scalar
		end
		local y2=y1+(self.cool_down_dig/(begin_cool_down/4))*scalar
		y1=y1+(self.cool_down_dig/(begin_cool_down/2))*scalar
		zspr(self.frame_shovel_bottom_ready,x,y1,self.turned)
		zspr(self.frame_shovel_top_ready,x2,y2,self.turned)
	end

	function self:draw_boundary()
		local x1=self.x1
		local x2=self.x2
		local y1=self.y1
		local y2=self.y2
		local x3=self.queue.x1
		local x4=self.queue.x2
		local y3=self.queue.y1
		local y4=self.queue.y2
		local x5=self.dig_target.x1
		local x6=self.dig_target.x2
		local y5=self.dig_target.y1
		local y6=self.dig_target.y2
		rectfill(x1,y1,x2,y2,8)
		rectfill(x3,y3,x4,y4,10)
		rectfill(x5,y5,x6,y6,11)
	end

	function self:draw_shadow()
		if self.sz<0 then
			local m=big_size/4
			self:draw_shadow_line(-1,m)
			self:draw_shadow_line(0,m)
			self:draw_shadow_line(1,m)
		end

		if self:dig() then
			local m=big_size/4
			if self.turned then
				m-=big_size-2*scalar
			else
				m+=big_size-2*scalar
			end
			self:draw_shadow_line(-1,m)
			self:draw_shadow_line(0,m)
			self:draw_shadow_line(1,m)
		end
	end

	function self:draw_shadow_line(n,m)
		local a=scalar
		local b=mid(big_size/4,self.sz*a/self.boost,big_size/2)
		local x=self.x+m
		local y=self.y+2*(big_size)

		draw_shadow_line(a,b,n,x,y)
	end

	function self:die()
		_update=over_update
		_draw=over_draw
	end

	function self:lose_ghosts()
		self.emote=3*begin_cool_down
		for ghost in all(ghosts) do
			--ghost:gets_lost()
			ghost:set_to_scatter()
			del(ghosts,ghost)
		end
	end
	
	return self
end
-->8
--ghost

--ghost_speed=.25*scalar
ghost_float_freq=1/100
ghost_float_amp=2
ghost_float_disp=10
ghost_selected=1
--ghost_cool_down=60
ghost_cool_down=100

function ghost_new(x0,y0,num)
	local ghost={
		type="ghost",
		x=x0,
		y=y0,
		n=num,
		dx=0,
		dy=0,
		tt=flr(rnd(1/ghost_float_freq)),
		hover_p=0,
		hover_y=0,
		turned=false,
		--frame_head=rnd({33,34,35,36,37}),
		--frame_head=rnd({33,37}),
		--frame_head=33,
		frame_head={32,33,34,35,36},
		frame_body={49,50,49,51},
		frame_body_index=1,
		x1=x0,
		x2=x0+big_size,
		y1=y0,
		y2=y0+big_size*2,
		state='recall',
		selected=false,
		cool_down=0,
		health=90,

		target=cemetary:random_target(),
	}

	function ghost:update()
		ghost.tt=inc_tt(ghost.tt)
		ghost.cool_down=max(0,ghost.cool_down-1)
		ghost:process()
		ghost:collision()
		ghost:move()
		ghost:update_bounds()
		ghost:update_health()
		ghost:animate()
	end

	function ghost:recall()
		return ghost.state=='recall'
	end

	function ghost:follow()
		return ghost.state=='follow'
	end

	function ghost:track()
		return ghost.state=='track'
	end

	function ghost:find()
		return ghost.state=='find'
	end

	function ghost:lost()
		return ghost.state=='lost'
	end

	function ghost:scatter()
		return ghost.state=='scatter'
	end

	function ghost:draw()
		if debug and debug_select and ghost.selected then
			pal(7,12)
			pal(7,13)
			pal(7,8)
			pal(7,flr(ghost.health/16))
		end
		ghost:draw_head()
		ghost:draw_body()
		pal()
		palt(0,false)
		palt(1,true)
	end

	function ghost:process()
		if ghost:recall() then
			ghost:recall_to_player()
		elseif ghost:follow() then
			ghost:follow_player()
		elseif ghost:track() then
			ghost:track_target()
		elseif ghost:find() then
			ghost:find_target()
		elseif ghost:lost() then
			ghost:gets_lost()
		elseif ghost:scatter() then
			ghost:scatters()
		else
			assert(false)
		end
	end

	function ghost:collision()
		local x1=self.x1+self.dx
		local x2=self.x2+self.dx
		local y1=self.y1+self.dy
		local y2=self.y2+self.dy
		if x1<0 and self.dx<0 then
			self.dx=0
		end
	    if x2>cemetary.width and self.dx>0 then
			self.dx=0
		end
		if y2<horizon and self.dy<0 then
			self.dy=0
		end
		if y2>cemetary.height+horizon and self.dy>0 then
			self.dy=0
		end
	end

	function ghost:move()
		ghost.x+=ghost.dx
		ghost.y+=ghost.dy
		if ghost.dx<0 then
			ghost.turned=true
		elseif ghost.dx>0 then
			ghost.turned=false
		end
	end

	function ghost:recall_to_player()
		ghost.state='recall'
		ghost.target=player.queue
		ghost:move_to()
	end

	function ghost:follow_player()
		ghost.state='follow'
		ghost.health=min(100,ghost.health+.01)
		ghost.target=player:get_rotation(ghost.n)
		ghost:move_to()
	end

	function ghost:track_target()
		ghost.state='track'
		ghost:move_to()
	end

	function ghost:find_target()
		ghost.state='find'
		ghost:move_to()
	end

	function ghost:gets_lost()
		ghost.state='lost'
		ghost:move_to()
	end

	function ghost:scatters()
		ghost.state='scatter'
		ghost.target=player.queue
		ghost:move_to()
	end

	function ghost:set_to_scatter()
		ghost.state='scatter'
		ghost.cool_down=ghost_cool_down
	end

	function ghost:move_to()
		local dist=distance(ghost,ghost.target)
		local a=player_max_speed
		if ghost:recall() and dist<a then
			ghost:add_to_queue()
		elseif ghost:track() and ghost.cool_down==0 then
			ghost.target:unsubscribe(ghost)
			ghost:recall_to_player()
		elseif ghost:find() and ghost.cool_down==0 then
			ghost:recall_to_player()
		elseif ghost:scatter() and ghost.cool_down==0 then
			ghost:gets_lost()
		else
			if ghost:track() and dist<a then
				ghost.health=max(0,ghost.health-1)
				ghost.target:drain()
			end
			if ghost:lost() then
				if not ghost.target or tt%100==0 then
					ghost.target=cemetary:random_target()
				end
			end
			local q=ghost.target
			local qx=(q.x1+q.x2)/2
			local qy=(q.y1+q.y2)/2
			local sx=(ghost.x1+ghost.x2)/2
			local sy=(ghost.y1+ghost.y2)/2
			local angle=atan2(qx-sx,qy-sy)
			if ghost:scatter() then
				angle+=.5
			end
			ghost.dx=cos(angle)*min(a,dist)
			ghost.dy=sin(angle)*min(a*y_scalar,dist)
			ghost.angle=angle
			ghost.selected=q.selected
		end
	end

	function ghost:add_to_queue()
		ghost.n=#ghosts
		add(ghosts,ghost)
		ghost:follow_player()
	end

	function ghost:update_bounds()
		ghost.x1=ghost.x
		ghost.x2=ghost.x+big_size
		ghost.y1=ghost.y
		ghost.y2=ghost.y+big_size*2
	end

	function ghost:update_health()
		if ghost.health<=0 then
			--ghost:die()
			ghost:gets_lost()
		end
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

	function ghost:get_frame_head()
		local n=#ghost.frame_head
		local i=flr(ghost.health/100*n)
		return ghost.frame_head[mid(1,n-i+1,n)]
	end

	function ghost:draw_head()
		local x=ghost.x
		local y=ghost.y+ghost.hover_y
		local f=ghost:get_frame_head()
		zspr(f,x,y,ghost.turned)
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

	function ghost:action()
		local enemy=rnd(get_enemy_target_select())

		if enemy then
			ghost.state='track'
			enemy:subscribe(ghost)
			ghost.target=enemy
			ghost.cool_down=ghost_cool_down
		else
			ghost.state='find'
			ghost.target=player.cmd_target
			ghost.cool_down=ghost_cool_down
		end
	end

	function ghost:die()
		del(sprites,ghost)
		--del(ghosts,ghost)
	end

	function ghost:on_notify(event,target)
		if event=='death' then
			if not ghost:follow() then
				ghost:recall_to_player()
			end
		elseif event=='move' then
			if ghost:track() then
				ghost.target=target
			end
		else
			print(event)
			assert(false)
		end
	end

	return ghost
end

ghosts={}
function ghosts_command()
	local m=#ghosts
	if m>0 and ghost_selected<=m then
		local ghost=ghosts[ghost_selected]
		del(ghosts,ghost)
		ghost:action()
		update_ghosts()
	end
end

function update_ghosts()
	local n=0
	for ghost in all(ghosts) do
		ghost.n=n
		n+=1
	end
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
		subscribers={},
		health=20,
	}

	function skeleton:update()
		skeleton.tt=inc_tt(skeleton.tt)
		skeleton:update_health()
		skeleton:move()
		skeleton:update_bounds()
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

	function skeleton:update_health()
		if skeleton.health<=0 then
			skeleton:die()
		end
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
		local x1=skeleton.x
		local x2=skeleton.x+big_size
		local y1=skeleton.y+big_size*2-scalar
		local y2=skeleton.y+big_size*2+scalar
		skeleton.x1=x1
		skeleton.x2=x2
		skeleton.y1=y1
		skeleton.y2=y2
		skeleton:notify("move",skeleton)
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
				player:lose_ghosts()
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
		skeleton:notify('death',skeleton)
		skeleton.subscribers={}
		del(sprites,skeleton)
		del(enemies,skeleton)
	end

	function skeleton:subscribe(subscriber)
		add(skeleton.subscribers,subscriber)
	end

	function skeleton:unsubscribe(subscriber)
		del(skeleton.subscribers,subscriber)
	end

	function skeleton:notify(event,data)
		for subscriber in all(skeleton.subscribers) do
			subscriber:on_notify(event,data)
		end
	end

	function skeleton:drain()
		skeleton.health=max(0,skeleton.health-1)
	end
	
	return skeleton
end

enemies={}
function get_enemy_target_select()
	local target=player.cmd_target
	local enemy_select={}
	for enemy in all(enemies) do
		if collision(target,enemy) then
			add(enemy_select,enemy)
		end
	end
	return enemy_select
end
-->8
--map

cemetary={}

screen_width=128
screen_height=128
horizon=64

moon_r=16*sqrt(scalar)
moon_x=96
moon_y=20-10*(scalar-1)

num_stars=100/scalar
num_clouds=2
cloud_div=(128+32)/num_clouds
--num_grave_cols=12
--num_grave_rows=6
num_grave_cols=3
num_grave_rows=3
sky_limit=-1000

function cemetary_init()
	local world={
		--width=128,
		--height=128-horizon,
		width=128*2,
		height=128,
		stars={},
		clouds={},
		graves={},
	}

	function world:generate_graves()
		local ngc=num_grave_cols*level
		local ngr=num_grave_rows*level
		local gw=big_size+3*scalar
		local gh=big_size+3*scalar
		world.width=gw*(ngc+2)
		world.height=gh*(ngr)

		for j=0,ngc do
			for k=0,ngr-1 do
				local x=gw*j
				local y=gh*k+horizon/scalar-big_size*(level-1)
				local f=rnd({10,11,12,13})
				local d=rnd({26,27,28,29})
				local h=grave_height(f)
				if on_path(j,k) then
				elseif rnd(1)<0.4 then
				else
					add(world.graves,{
						f=f,
						x=x,
						y=y,
						d=d,
						h=h,
						--open=rnd(1)<0.2,
						open=false,
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
	end

	function world:init_clouds()
		for i=1,num_clouds do
			local cx=rnd(cloud_div/num_clouds)
			local cdx=cloud_div*i-64+cx
			add(world.clouds, {
				x=cdx,
				y=rnd_cloud_y(),
				dx=rnd_cloud_dx(),
				frame=70,
			})
		end
	end

	function world:init_stars()
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
	end

	function world:try_dig()
		local x1=player.dig_target.x1
		local y1=player.dig_target.y1
		local x2=player.dig_target.x2
		local y2=player.dig_target.y2
		local cx=(x1+x2)/2
		local cy=(y1+y2)/2
		local g=world:get_grave(cx,cy)
		if g then
			if g.open then
				--g.open=false
				--sfx(1)
			else
				g.open=true
				open_grave(g)
				sfx(2)
			end
		end
	end

	function world:collision(p)
		if p.y1<horizon then
			return sky_limit
		end
		return world:hit_tombstone(p)
	end

	function world:hit_tombstone(p)
		local h=0
		foreach(world.graves,function(grave)
			local b=get_tombstone_boundary(grave)
			if collision(b,p) then
				h=grave.h*scalar
			end
		end)
		return h
	end

	function world:get_grave(cx,cy)
		local g=nil
		foreach(world.graves,function(grave)
			local x=grave.x
			local y=grave.y+big_size*2
			local w=big_size
			local h=big_size
			if cx>x and cx<x+w and cy>y and cy<y+h then
				g=grave
			end
		end)
		return g
	end

	function world:zoom_init(size)
		big_size=size
		scalar=big_size/cell_size
		init_scalars()
		world:init_clouds()
		world:init_stars()
	end
	
	function world:update()
		world:update_clouds()
		for grave in all(world.graves) do
			if not grave.open then
				return
			end
		end
		ready_game=false
		level+=1
		if level<4 then
			_update=level_update
			_draw=level_draw
		else
			level=1
			_update=over_update
			_draw=over_draw
		end
	end
	
	function world:draw()
		--camera
		camera(0,camy)

		--draw sky
		cls(1)

		world:draw_stars()
		world:draw_moon()
		draw_ground()


		camera(camx,camy)
		world:draw_lantern_light()

		world:draw_clouds()

		--world:draw_cemetary()
	end

	function world:draw_lantern_light()
		local c=player.cmd_target
		local x1=c.x1
		local y1=c.y1
		local x2=c.x2
		local y2=c.y2
		clip_ground()
		if not player:dig() then
			ovalfill(x1,y1,x2,y2,14)
		end
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

	function world:draw_moon()
		circfill(moon_x,moon_y,moon_r,14)
		circfill(moon_x+sqrt(25*scalar),moon_y-sqrt(25*scalar),moon_r,1)
	end

	function world:random_target()
		local x=rnd(world.width-big_size*2)
		local y=rnd(world.height-big_size*2)+horizon
		return {x1=x,y1=y,x2=x+big_size,y2=y+big_size}
	end

	return world
end

--path_cols={4}
--path_rows={3}
function on_path(j,k)
	return j%4==0 or k%3==0
end

function grave_height(f)
	local h_list={7,8,7,4}
	return -1*h_list[f-9]
end

function update_grave(g)
end

function open_grave(g)
	if #ghosts>0 and rnd(1)<0.5 then
		init_skeleton(g)
	else
		init_ghost(g)
	end
end

function get_tombstone_boundary(g)
	local x1=g.x
	local x2=g.x+big_size
	local y1=g.y+2*big_size-scalar
	local y2=g.y+2*big_size
	assert(y2>y1)
	return {
		x1=x1,
		y1=y1,
		x2=x2,
		y2=y2,
	}
end

function draw_grave_boundary(g)
	local b=get_tombstone_boundary(g)
	--print(b.x1..","..b.y1)
	--print(b.x2.." "..b.y2)
	assert(b.y2>b.y1)
	rectfill(b.x1,b.y1,b.x2,b.y2,8)
	rectfill(unpack(b),8)
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
	return moon_y-moon_r*sqrt(scalar+1)-rnd(scalar*2)-big_size/2
end

function rnd_cloud_dx()
	return rnd(1)/4*sqrt(scalar)+0.25*sqrt(scalar)
end

function draw_cloud(c)
	bspr(c.frame,c.x,c.y,false,false)
end

function draw_star(s)
	zset(s.x,s.y,7)
end

function draw_ground()
	local h1=horizon
	local h2=h1+cemetary.height
	rectfill(0,h1,screen_width,h2,2)
	--rectfill(0,horizon,128,128,2)
end
-->8
--globals

function init_scalars()
	player_speed=.25*scalar
	gravity=0.2*scalar
	player_max_speed=1.5*scalar
	y_scalar=.5*scalar
	bound_width=4*scalar
	bound_height=2*scalar
	skeleton_crawl_speed=0.5*scalar
	skeleton_float_speed=0.3*scalar
	moon_r=16*sqrt(scalar)
	moon_y=20-10*(scalar-1)
	num_stars=100/scalar
	window_width=screen_width/scalar
	window_height=screen_height/scalar
end
__gfx__
00000000118888881188888811888888119911110000000011181111000000000000000011111111111111111115511111111111111111110000000000000000
000000001888aaaa1888aaaa1888aaaa179991110000000011888111000000000000000011111111155555111115511111555511111111110000000000000000
0070070088affff188affff188affff1779881110000000018888811000000000000000011111111155555511555555115555551111111110000000000000000
0007700088ff0f0188ff0f0188ff0f017718a8110000000018888811000000000000000016666661150005511555555115000051111111110000000000000000
00077000aaf070f1aaf070f1aaf070f1718aaa810000000011181111000000000000000016606061155555511115511115555551115555110000000000000000
00700700aaff0fffaaff0fffaaff0fff118aaa810000000011181111000000000000000016666661155005511555555115555551155555510000000000000000
00000000aaeffff1aafffff1aafffff1118aaa810000000011181111000000000000000011616161155555511500005115555551150005510000000000000000
00000000aafeef11aafeef11aaffef11118888810000000011181111000000000000000011111111155555511555555115555551155555510000000000000000
0000000019ffff9119ffff9119ffff91111111110000000011181111000000000000000016666661111111111111111111111111111111110000000000000000
00000000197777911977779119777791111111110000000011181111000000000000000011161111111444441444441111444441111444410000000000000000
00000000199999911999999119999991111111110000000011181111000000000000000011666611444444444444444414444444114444440000000000000000
00000000199999911999999119999991111111110000000011997711000000000000000011161111444444444444444444444444444444440000000000000000
00000000199919911ff1199119991ff1111111110000000011997711000000000000000011666111444444414444444444444444444444440000000000000000
000000001ff11ff11aaa1ff11ff11aaa111111110000000011181111000000000000000011161111114444411444444114444444444444440000000000000000
000000001aaa1aaa11111aaa1aaa1111111111110000000011181111000000000000000011111111111111111111111111111111111111110000000000000000
00000000111111111111111111111111111111110000000011181111000000000000000011111111111111111111111111111111111111110000000000000000
11111111111111111111111111111111111111110000000000000000000000000000000011111111111444441444441111444441111444410000000000000000
11111111111111111111111111111111111111110000000000000000000000000000000011111116444400044400044414400044114400440000000000000000
11177711111777111117771111177711111777110000000000000000000000000000000011161616400000044000000444000004444000040000000000000000
11777771117777711177777111777771117777710000000000000000000000000000000011666666400000000000000440000004400000040000000000000000
17777771177777711777777117777771177777710000000000000000000000000000000011161616400000000000000000000000000000000000000000000000
17000001177070711707770117007001177070710000000000000000000000000000000011111616140000044000000440000000000000000000000000000000
17007001177070711770707117707071170777010000000000000000000000000000000011111116114444411444444114444444444444440000000000000000
17777771177777711777777117777771177777710000000000000000000000000000000011111111111111111111111111111111111111110000000000000000
00000000177777711777777117777771177777710000000011711111171188110000000000000000000000000000000000000000000000000000000000000000
00000000177777711777777117777771177777710000000017711111177188810000000000000000000000000000000000000000000000000000000000000000
00000000177717111771717117717171177171710000000089988888899888880000000000000000000000000000000000000000000000000000000000000000
00000000171711111771111111711111117111110000000019911111199188810000000000000000000000000000000000000000000000000000000000000000
00000000111111111711111111111111111111110000000011111111111188110000000000000000000000000000000000000000000000000000000000000000
00000000111111111111111111111111111111110000000011111111111111110000000000000000000000000000000000000000000000000000000000000000
00000000111111111111111111111111111111110000000011111111111111110000000000000000000000000000000000000000000000000000000000000000
00000000111111111111111111111111111111110000000011111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000011111111111111111111111111111111000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000011111111111111111111111111111111000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000011111111115555551115555111111111000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000011111111556666665556666511111111000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000011111115666666666666666651111111000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000011111115666666666666666655551111000000000000000000000000000000000000000000000000
11111111111111111111115555111111000000000000000011111156666666666666666656665111000000000000000000000000000000000000000000000000
11111111111111111111556666551111000000000000000011111156666666666556666666666511000000000000000000000000000000000000000000000000
11111111555551115555555666651111000000000000000011111156666666666665666666666511000000000000000000000000000000000000000000000000
11111155666665556665666666665111000000000000000011111156666666666666666666666511000000000000000000000000000000000000000000000000
11111566666665656666666666665111000000000000000011111556666556666666666666666511000000000000000000000000000000000000000000000000
11111566666666666666666666665111000000000000000011115666665666666666666666655111000000000000000000000000000000000000000000000000
11115666666666666666666666655111000000000000000011115666665666666666666666651111000000000000000000000000000000000000000000000000
11115666666666666666666666655111000000000000000011156666666666666666666666651111000000000000000000000000000000000000000000000000
11115566666666666666666666555111000000000000000011156666666666666666555566651111000000000000000000000000000000000000000000000000
11155666666666666666666666665111000000000000000011156666666666666665666656651111000000000000000000000000000000000000000000000000
11156566666666666666666666665111000000000000000011155666666666666666666666555111000000000000000000000000000000000000000000000000
1156656d666666666666666666665111000000000000000011556666666666656666666665666511000000000000000000000000000000000000000000000000
11566665666666666666666666dd5111000000000000000011566666666666566666666666666651000000000000000000000000000000000000000000000000
11566666666666666666666666551111000000000000000015666666666666566666666666666d51000000000000000000000000000000000000000000000000
115d6666666666666666666666665511000000000000000015666556666666666666666ddd66dd51000000000000000000000000000000000000000000000000
115d6666666666666dddddd666666511000000000000000015d66665555666666666dddd5dddd511000000000000000000000000000000000000000000000000
115dd666666666dddd5dd5dd66666651000000000000000015dd6666666666666666d55515555111000000000000000000000000000000000000000000000000
1115d666666666d55555555d66666d510000000000000000115d6666666666666666d51111111111000000000000000000000000000000000000000000000000
1115ddd6666666ddd51115dd6666dd510000000000000000115ddd666dddd666666dd51111111111000000000000000000000000000000000000000000000000
111155ddd666ddd55111115dd66dd511000000000000000011155ddddd55dd6666dd511111111111000000000000000000000000000000000000000000000000
11111155ddddd55111111155dddd551100000000000000001111155555115dddddd5111111111111000000000000000000000000000000000000000000000000
11111111555551111111111155551111000000000000000011111111111115555551111111111111000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000011111111111111111111111111111111000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000011111111111111111111111111111111000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000011111111111111111111111111111111000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000011111111111111111111111111111111000000000000000000000000000000000000000000000000
__label__
1111111155666666555566666666666666666666666666666666dddddd6666dddd5511111111eeeee11111111111155666666555566666666666666666666666
1111111155666666555566666666666666666666666666666666dddddd6666dddd5511111111eeeee11111111111155666666555566666666666666666666666
1111111155dd6666666655555555666666666666666666dddddddd55dddddddd551111111111eeeee11111111111155dd6666666655555555666666666666666
1111111155dd6666666655555555666666666666666666dddddddd55dddddddd55111111111eeeeee11111111111155dd6666666655555555666666666666666
1111111155dddd66666666666666666666666666666666dd555555115555555511111177111eeeeee11111111111155dddd66666666666666666666666666666
1111111155dddd66666666666666666666666666666666dd555555115555555511111177111eeeeee11111111111155dddd66666666666666666666666666666
111111111155dd66666666666666666666666666666666dd55111111111111111111117711eeeeeee1111111111111155dd66666666666666666666666666666
111111177155dd66666666666666666666666666666666dd55111177111111111111111111eeeeeeee111111111111155dd66666666666666666666666666666
111111177155dddddd666666dddddddd666666666666dddd55111177111111111111111111eeeeeeee111111111111155dddddd666666dddddddd66666666666
111111111155dddddd666666dddddddd666666666666dddd55111111111111111117711111eeeeeeee111111111111155dddddd666666dddddddd66666666666
1111111111115555dddddddddd5555dddd66666666dddd5511111111111111111117711111eeeeeeeee111111111111115555dddddddddd5555dddd66666666d
1111111111115555dddddddddd5555dddd66666666dddd5511111111111111111111111111eeeeeeeee111111111111115555dddddddddd5555dddd66666666d
11111111111111115555555555111155dddddddddddd551111111111111111111111111111eeeeeeeee1111111111111111115555555555111155ddddddddddd
11111111111111115555555555111155dddddddddddd551111111111111111111111111111eeeeeeeeee111111111111111115555555555111155ddddddddddd
11111111111111111111111111111111555555555555111111111111111111111111111111eeeeeeeeeee1111111111111111111111111111111155555555555
111111111111111111111111111111115555555555551111111111111111111111111111111eeeeeeeeee1111111111111111111111111111111155555555555
111111111111111111111177111111111111111111111111111111111111111111111111111eeeeeeeeeee111111111111111111111111111111111111111111
111111111111111111111177111111111111111111111111111111111111111111111111111eeeeeeeeeeee11111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111771111111111111111eeeeeeeeeeee1111111111111111111111111111111111111111
1111111111111111111111771111111111111111111111111111111111771111111111111111eeeeeeeeeeeee111111111111111111111111111111111111111
1111111111111111111111771111111111111111111111111111111111111111111111111111eeeeeeeeeeeeee11111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeee11111111111111111111111e111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeee111111111111111111111e1111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeeeeee111111111111111eeee1111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeeeeeeee111111111eeeeee11111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeeeeee11111111111111111
11111111111111111111111111111111771111111111111111111111111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeeee111111111111111111
1111111111111111117711111111111177111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeee11111111111111111111
11111111111111111177111111111111177777711111111111111111111771111111111111111111111111eeeeeeeeeeeeeeeeeeeee111111111111111111111
11111111111111111111111111111111177777711111111111111111111771111111111111111111111111111eeeeeeeeeeeeeee111111111111111111111111
11111111111111111111111111117717777777777111111111111111111111111111111111111111111111111111eeeeeeeee111111111111111111111111111
11111111111111111111111111117717777777777111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111117777777777771111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111117777777777771111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111117700770077771111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111117700770077771111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17711111111111111111111111111117700770077771111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17711111111111111117711111111117700770077771111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111117711111111117777777777771111111111111111111111111111111111111111111177111111111111111111111111111111111111111
11111111111111111111111111117717777777777771111111111111111111111111111111111111111111177111111111111111117711111111111111111111
11111111111111111111111111117717777777777771111111111111111111111111111111111111111111111111111111111111117711111111111111111111
11111117711111111111111111111117777777777771111111118811111111111111111111111111111111111111111111111111111111111111111111111111
11111117711111111111111111111117777777777771111111118811111111111111111111111111111111111111111111111111177111111111111111111111
11111111111111111111111111111117777777777771111111888888111111111111111111111111111111111111111111111111177111111111111111117711
11111111111111111111111111111111177117777771111111888888111111111111111111111111111111111111111111111111111111111111111111117711
11111111111111111111111111111111177117777771111188888888881111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111117711771111188888888881111111111111111111111111111111111111111111111111111111111111111177111
11111111111111111111111111111111111117711777711188888888881188888888888811111111111111111111111111111111111111111111111111177111
11111111111111111111111111111111111111111117711188888888881188888888888811111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111177111111111111881111888888aaaaaaaa11111111111111111111111111111111111111117711111111111111
1111111111111111111111111111111111111177111111111111881111888888aaaaaaaa11111111111111111771111111111111111111117711111111111771
111111111111111111111111111111111111111111111111111188118888aaffffffff1111111111111111111771111111111111111111111111111111111771
111111111111111111111111111111111111155551111111111188118888aaffffffff1111111111155551111111111111111111111111111111111111111111
111111111111111111111111111111111111155551111111111188118888ffff00ff001111111111155551111111111111111111111111111111111111111117
111177111111111111111111111111111111155551111111111188118888ffff00ff001111111111155551111111111111111111111111111111111117711117
11117711111111111111111111117711111115555111111111118817aaaaff007700ff1111111111155551111111111111111177111111111111111117711111
11111111111111111111111111117711155555555555511111118817aaaaff007700ff1111111555555555555111111111111177111111111111111111111111
11111111111111111111111111111111155555555555511111118811aaaaffff00ffffff11999955555555555111111111111111111111111111111111111111
11111111111111111111111111111111155555555555511111118811aaaaffff00ffffff11999955555555555111111111111111111111111111111111111111
11111111111111111111111111111111155555555555511111118811aaaaeeffffffff1177999999555555555111111111111111111111111111111111111111
11111111111111111111111111111111111115555111111111118811aaaaeeffffffff1177999999155551111111111111111111111111111111111111111111
11111111111111111111111111111111111115555111111111118811aaaaffeeeeff117777998888155551111111111111111111111111111111111111111111
22222222222222222222222222222222255555555555522222228822aaaaffeeeeff227777998888555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2222
222222222222222222222222222222222555555555555222229999777799ffffffff9977772288aa885555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2
222222222222222222222222222222222550000000055222229999777799ffffffff9977772288aa880000055eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222225500000000552222299997777997777777799772288aaaaaa8800055eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222225555555555552222299997777997777777799772288aaaaaa8855555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222225555555555552222222882222999999999999222288aaaa998855555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222222002200220022222222882222999999999999222288aaaa9988eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222200220022002222222222882222999999999999222288aaaa9988eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222200240044004442222222882222999999999999222288aaaa998844444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222220022004400444442222222882222999999229999222e888888888844444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222220024004400444444422222882222999999229999222e88888888884444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222224444444444444422222222222ffff2222ffff22eeeeeee444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222444444444444444422222222222ffff2222ffff22eee4444444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222444444444444444422222222222aaaaaa22aaaaaaeee4444444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
222222222222222222222222222222244444444444444442222222222555555552aaaaaaeee4444555555554444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
222222222222222222222222222222244444444444444442222222222555555552222222eee4444555555554444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222224444444444444422222222555555555555222222ee4455555555555544eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222224444444444444422222222555555555555222222ee4455555555555544eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
22222222222222222222222222222222222222222222222222222225500000000552222222eee550000000055eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
22222222222222222222222222222222222222222222222222222225500000000552222222eee550000000055eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
222222222222222222222222222222222222222222222222222222255555555555522222222ee555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2222222222222222222222222222222222222222222222222222222555555555555222222222e555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
22222222222222222222222222222222222222222222222222222225555555555552222222222555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
22222222222222222222222222222222222222222222222222222225555555555552222222222555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
22222222222222222222222222222222222222222222222222222225555555555552222222222555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
22222222222222222222222222222222222222222222222222222225555555555552222222222555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2
22222222222222222222222222222222222222222222222222222225555555555552222222222555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2222
22222222222222222222222222222222222222222222222222222225555555555552222222222555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee222222
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeeeeeeeeeeeeeeeeeeeee2222222222
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeeeeeeeee2222222222222222
22222222222222222222222222222222222222222222222222222222222444444442222222222444444444422222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222444444442222222222444444444422222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222244444444444422222244444444444444442222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222244444444444422222244444444444444442222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222444444444444444422222244444444444444442222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222444444444444444422222244444444444444442222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222444444444444444422222244444444444444442222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222444444444444444422222244444444444444442222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222444444444444444422222222444444444444222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222444444444444444422222222444444444444222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222

__sfx__
00010000076500d65014650246501d650156500c65007650066500265000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001e65011650096500765006650056500565005650056500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000076500d65014650246501d650156500c65007650066500265000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
