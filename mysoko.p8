pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--init & stargame

--sprite flags
--0:wall
--1:

--blank desktop=(102*8,16*8)

function _init()
	
	--screen shake variables
	intensity = 0
	shake_control = 2
	ground_tile = 49
	goal_tile = 13
	--game timer
	t=0
	fadeperc=1
	debug={}
	cam_x,cam_y=0,0
	p_x,p_y=22,10
	level=1
	servertext={"server 1","server 2","server 3"}
	--normal,squish up,squish right
	p_anims={112,116,117,118}
	
	p_ani=p_anims[1]
	--camera pos per lvl
	levelx={17,34,51,68,85,102,0,17,34,51,68,85,102}
	levely={0,0,0,0,0,0,16,16,16,16,16,16,16}

	--player pos per lvl
	plx={19,37,59,73,87,106,6,22,41,54,69,86}
	ply={9,10,12,7,10,9,25,22,22,25,21,21}
	
	newstext = "breaking news: an unknown computer virus is sweeping the city. lock your pc!"

	hubtext = {
		{">password: **********",
		">ipscan 132.55.23.1.8080",
		">select a server to begin"},
		{">message from employer:",
		">server 1 destroyed",
		">two more to go. . ."},
		{">message from employer:",
		">server 2 destroyed",
		">two more to go. . ."},
		{">message from employer:",
		">server 3 destroyed",
		">two more to go. . ."},
		{">message from employer:",
		">complete the last job.",
		">your pay will be $_,___."},
	}
	
	--player location given the level

	boxtles={6,7,8,9,10,11,12}
	goaltles={22,23,24,25,26,27,28}

	dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}

	dirx={-1,1,0,0,1,1,-1,-1}
	diry={0,0,-1,1,-1,1,1,-1}
	
	box={}
	goal={}
	--lock stuff
	lock={0,0,0}--keeps track of completed locks
	locksprite={64,64,64}
	lockpuff=0
	locktimer=0
	completedworlds={0,0,0}
	acheivement={0,0,0}

	steps={0,0,0,0,0,0,0,0,0,0,0,0}
	optsteps={110,115,65,95,157,28,60,50,50,34,11,12}--optimal steps
	slbx=nil --SLIDE BOX
	
	--particles
	part={}
	--scanline stuff
	showscan=true
	yscan=38
	yscanstart=38
	yscanend=120 -- -42+1

	blinkframe=0--used to blink text
	blinkspeed=10
	blinkcolor=7
	blinkindex=1
	menucountdown=-1
	init_menu()
	--used in wait function
	wait_time=0
	next_function=init_menu
	coin_puff=false
	show_coin=true
	templvl=level
	newsworks=true
	
end

function init_level()
	--music(32,1000)--level music
	yscan=yscanstart
	goal={}
	box={}
	buttbuff=-1	
	p_ox,p_oy=0,0--PLAYER OFFSET
	--OFFSET ALLOWS PLAYER TO SLIDE
	--INTO A GIVEN SPOT WITHOUT
	--LOSING POSITION		
	p_flp=false
	p_mov=nil
	p_t=0--ANIMATION TIMER (0 TO 1)
	_upd=upd_refresh_level
	_drw=drw_level
	--music(32,1000)
end
-->8
--update


function _update()
	blinktext()
	if intensity > 0 then shake() end
	t+=1--where we are in the anim
	_upd()
	--update particles
	updateparts()
end 

function lockanim(i)
	if locktimer<=1 then
		locksprite[i]+=2
	end
	locktimer-=1
end

function upd_open_lock()
	--prepare lock animation
	local lockdone = true
	for i=1,3 do
		--check to see if lock has animated
		if lock[i]==1 and locksprite[i]<70 then
			if locktimer<1 then
				lockpuff=i
				locktimer=5
			end
			lockanim(i)
			lockdone = false
		end
	end	
	if lockdone then
		wait_time=30
		next_function=upd_refresh_level--next function after wait
		_upd=upd_wait
	end
end

function upd_wait() 
	if wait_time <=0 then
		_upd=next_function
		fadeout(0.5)
	end
	wait_time-=1
	
end
function upd_wait_level_end()
	show_coin=false
	if wait_time <=0 then
		show_coin=true
		init_hub()
		fadeout(0.5)
	end
	wait_time-=1
end

function checkacheivement(world,start)
	local give = true
	for i = start,start+3 do
		if steps[i]>optsteps[i] then
			give = false
		end
	end
	if give then
		acheivement[world]=1
	else
		acheivement[world]=-1--failed
	end
end

function upd_game()
	btn_buffer()
	do_btn_buffer(buttbuff)
	buttbuff=-1
	if checksolved() then		
		if level%4 == 0 then--end of world
			if level<5 then
				completedworlds[1]=1
				checkacheivement(1,1)
				wait_time=30
				_upd=upd_wait_level_end
				coin_puff=true
			elseif level<9 then
				completedworlds[2]=1
				checkacheivement(2,5)
				wait_time=30
				_upd=upd_wait_level_end
				coin_puff=true
			else
				completedworlds[3]=1
				checkacheivement(3,9)
				wait_time=30
				_upd=upd_wait_level_end
				coin_puff=true
			end
		else
			intensity += shake_control--set the camera to shake
			level+=1
			modlvl=(level-1)%4+1
			lock[modlvl-1]=1--unlock previous lock
			_upd=upd_open_lock

		end		
		
		sfx(54)--end level
	end
end

function blinktext()
	local colors = {3,11,12,7}
	blinkframe+=1
	if blinkframe>blinkspeed then
		blinkframe=0
		blinkindex+=1
		if blinkindex > #colors then
			blinkindex=1
		end
		blinkcolor=colors[blinkindex]

	end
	
end

-->8
--draw

--WORKS FOR 2x2 AND SINGLE FRAME ANIMS
function create_ani_list(_sa,_ea,_delay,grid)
	local _ani={}
	--add delay
	if _delay>0 then
		for x=0,_delay do
			add(_ani,_sa)
		end
	end
	--add normal frames

	local length=_ea
	local skip=0
	if grid then
		length=(_ea-_sa)/2+_sa
	end
	for x=_sa,length do
		add(_ani,x+skip)
		if grid then
			skip+=1
		end
	end
	return _ani
end

function add_ani(_sa,_ea,_delay,_spd,_x,_y,_flp)
	local _ani = create_ani_list(_sa,_ea,_delay,false)
	local a={
		ani=_ani,
		spd=_spd,--SPD OF ANI LOWER BETTER?
		x=_x,
		y=_y,
		flp=_flp
	}
	add(anims,a)
end



function draw_bas_ani()
	for a in all(anims) do
		fm=getframe(a.ani,a.spd)
		drawspr(fm,a.x,a.y,a.flp)
	end
end

--ONLY ADD 2x2 ANIMATED GRIDS
function add_grid(_sa,_ea,_delay,_spd,_x,_y,_w,_h)
	
	local _ani=create_ani_list(_sa,_ea,_delay,true)
	
	local a={
		ani=_ani,
		spd=_spd,
		x=_x,
		y=_y,
		w=_w,
		h=_h

	}
	add(grids,a)
end

function drawgrids()
	for g in all(grids) do
		--SINCE LOOP STARTS AT 0
		gw,gh=g.w-1, g.h-1	
		for x=0,gw do
			for y=0,gh do
				sp=getframe(g.ani,g.spd)
				drawspr(y*16+sp+x,g.x+x*8,g.y+y*8,false)
			end
		end
	end
end


function sdrawgrid(stspr,_x,_y,_w,_h)
	_w,_h=_w-1,_h-1--since start 0	
	for x=0,_w do
		for y=0,_h do		
			drawspr(y*16+stspr+x,_x+x*8,_y+y*8,false)
		end
	end
end

function getframe(ani,spd)
	return ani[flr(t/spd)%#ani+1]
end

function drawspr(_spr,_x,_y,_flp)
	spr(_spr,_x,_y,1,1,_flp)	
end

function drawgamestuff()
	--(sa,ea,delay,spd,x,y,flp)
	--draw player

	if p_ani == p_anims[1] then
		add_ani(p_ani,p_ani+3,4,4,p_x*8+p_ox,p_y*8+p_oy,p_flp)
	else
		add_ani(p_ani,p_ani,4,4,p_x*8+p_ox,p_y*8+p_oy,p_flp)
	end
	--monitor
	add_ani(96,98,0,6,cam_x+3*8,cam_y+1*8,false)
	--chord
	add_ani(99,102,4,4,cam_x+4*8,cam_y+1*8,false)
	--draw desk
	sdrawgrid(45,cam_x+2*8,cam_y+1*8,3,2)
	--lower bar
	rectfill2(cam_x+1*8,cam_y+24,13*8+6,8,5)
	rectfill2(cam_x+1*8+1,cam_y+25,13*8+4,6,1)


	if coin_puff then
		particleshatter(16*3+cam_x+5*8+4,cam_y+1*8+4,{7,11,3})
		particleshatter(16*3+cam_x+5*8+4,cam_y+1*8+4,{7,11,3})
		particleshatter(16*3+cam_x+5*8+4,cam_y+1*8+4,{7,11,3})
		coin_puff=false			
	end
	if show_coin then--draw coin
		add_grid(37,43,4,4,16*3+cam_x+5*8,cam_y+1*8,2,2)
	end
	drawgrids()--draw grid animations
	drawparts()--particles
	drawlock()
	draw_bas_ani()--draw non-grid animations
end

function drawbox(b)
 	drawspr(b.tle,b.x*8+b.ox,b.y*8+b.oy,false)
end

function drawlock()
	for i=1,3 do
		
		sdrawgrid(locksprite[i],16*(i-1)+cam_x+5*8,cam_y+1*8,2,2)
		if lockpuff == i then
			particlepuff(16*(i-1)+cam_x+5*8+4,cam_y+1*8+4,{7,6,5})--draw puff
			lockpuff=0
		end
	end	
end



function _draw()
	grids={}
	anims={}
	_drw()
	checkfade()
	--draw debug
	local offst=0
	for txt in all(debug) do
		print(txt,cam_x+10,cam_y+offst,8)
		offst+=8
	end
end

function drw_level()
	cls()
	rectfill2(cam_x+1*8-2,cam_y+5*8-2,14*8+4,10*8+3,0)--pc background color
	--CHANGE TRANSPARENCY COLR
	drawspr(21,cam_x+14*8,cam_y+4*8,false)--draw pc logo (has pink)
	palt(0,false)
	palt(14,true)
	map()
	for b in all(box) do
		drawbox(b)
	end
	--draw everything else in the game
	drawgamestuff()
	drawlvltitle()
 	--RETURN TRANSPARENCY COLR
	palt(0,true)
	palt(14,false)
	draw_scanline()
	rectfill2(cam_x+2,cam_y+126,16*8-4,2,6)--lower pc (prevent showing in shake)
end
function drawlvltitle()
	print("level: "..templvl,cam_x+49,cam_y+1,3)
	print("steps: "..steps[templvl].."/"..optsteps[templvl],cam_x+36,cam_y+26,7)
end

--tool

function oprint8(_t,_x,_y,_c,_c2)
	for i=1,8 do
		print(_t,_x+1,_y+diry[i],_c2)		
	end
	print(_t,_x,_y,_c)
end

function rectfill2(_x,_y,_w,_h,_c)
	rectfill(_x,_y,_x+max(_w-1,0),_y+max(_h-1,0),_c)
end
function rrectfill2(_x,_y,_w,_h,_c)--draws box with round corner
	rectfill2(_x,  _y+1,_w,_h-2,_c)
	rectfill2(_x+1,_y  ,_w-2,_h,_c)
     end

function wait(_wait)
 repeat
		_wait-=1
		flip()
	until _wait<0
end
-->8
--gameplay

function moveplayer(dx,dy)--direction x and y are either 0, 1, or -1
	local newpx=p_x+dx
	local newpy=p_y+dy	
	
	if dx<0 then
		p_flp=true
	elseif dx>0 then
		p_flp=false
	end
	--planned tile to move to
	local tle=mget(newpx,newpy)
	--checkbox
	p_wall=false--used to change animations
	local bx = checkbox(newpx,newpy)
	--wall or box flag
	if fget(tle,0) or bx then
		p_sox=dx*8
		p_soy=dy*8
		p_ox,p_oy=0,0		
		p_mov=pbump--set to bump
		--box flag
		if bx then
			slbx=bx
			bx.dx=dx
			bx.dy=dy
		else
			sfx(61)--bump wall noise
		end
		p_wall=true
	else
		steps[level]+=1
		--no wall or box
		sfx(63)--walk sfx
		
		p_x+=dx
		p_y+=dy
		
		--SET OFFSET USED IN player loop
		p_sox=-dx*8
		p_soy=-dy*8
		
		p_ox,p_oy=p_sox,p_soy
		p_mov=pslide--set to slide into place
	end
	_upd=upd_p_loop--set player loop
	p_t=0
	
	
	
end

--this pauses player movement
--to animate
function upd_p_loop()
	btn_buffer()

	--wall animations
	if p_sox==0 then
		if p_wall then
			p_ani=p_anims[3]--bump wall
		else
			p_ani=p_anims[2]--squish up
		end
	else
		if p_wall then
			p_ani=p_anims[2]--squish left
		else
			p_ani=p_anims[3]--squish left
		end
	end
	p_t=min(p_t+0.3,1)

	p_mov() --moves the player offset by
	--trail particle
	particletrail(p_x*8+p_ox,p_y*8+p_oy)
	if p_t==1 then
		--call slide box
		p_ani=p_anims[1]--normal
		_upd=upd_game
		if slbx then
			movebox()
		end
	end
end

function pslide()
	p_ox=p_sox*(1-p_t)
	p_oy=p_soy*(1-p_t)
end

function pbump()
	local tme=p_t
	--go back the second half of the animation
	if p_t>0.5 then
		tme=1-p_t
	end
		p_ox=p_sox*tme
		p_oy=p_soy*tme
end

function btn_buffer()
	if buttbuff==-1 then
		buttbuff=getinput()
	end
end

function getinput()
	for i=0,5 do
		if btnp(i) then
			return i
		end
	end 
	return -1
end

function do_btn_buffer(_btn)
	if 0<=_btn and _btn<4 then
		moveplayer(dirx[_btn+1],diry[_btn+1])	
	end
 	if _btn==5 then--x key
		restartlevel()
 	end
end

function restartlevel()
	particlepuff(p_x*8,p_y*8,{7,11,3})
	init_codeslide()
	steps[level]=0
end
 
function init_codeslide()
	intensity += shake_control--set the camera to shake
	sfx(60)--slide noise
	--set the offset counter

	p_sox=(p_x-plx[level])*8--used to set p_ox (starting offset)
	p_soy=(p_y-ply[level])*8--used to set p_oy
	--set player to starting location
	p_x=plx[level]
	p_y=ply[level]
	p_ox,p_oy=p_sox,p_soy
	p_mov=pslide
	_upd=upd_codeslide--set player loop
	p_t=0
end

function upd_codeslide()
	btn_buffer()
	p_t=min(p_t+0.1,1)
	p_ani=p_anims[4]
	p_mov() --moves the player offset by
	particlecode(p_x*8+p_ox,p_y*8+p_oy,17,{7,11,3})--code trail particle
	if p_t==1 then
		particlepuff(p_x*8,p_y*8,{7,11,3})
		--call slide box
		p_ani=p_anims[1]--normal
		_upd=upd_game
		init_level()
		reload(0x1000, 0x1000, 0x2000)
	end
end

function checksolved()
	local solved = true	
	for g in all(goal) do
		if checkbox(g.x,g.y) then
			mset(g.x,g.y,goal_tile)
			if not g.flg then
				g.flg = true
				sfx(59)--click square into place
				intensity += 0.5--set the camera to shake
				particleshatter(g.x*8,g.y*8,{11})
  			end
		else
			mset(g.x,g.y,g.gf)
			g.flg=false
			solved = false
		end
	end
	return solved
end

function upd_refresh_level()
	local lx=levelx[level]
	local ly=levely[level]
	
	cam_x=8*lx
	cam_y=8*ly
	camera(cam_x,cam_y)--pixel location
	--player stuff
	if plx[level]+ply[level]>0 then
		p_x=plx[level]
		p_y=ply[level]
	else
		p_x=lx+1
		p_y=ly+5
	end

	--INITIALIZE BOX AND GOAL
	box={}
	goal={}
	--LOAD UP THE BOXES AND GOALS
	for x=lx,lx+15 do
		for y=ly,ly+15 do
			tle=mget(x,y)
			--ALL THE BOX TYPES
			for t in all(boxtles) do
				if t==tle then
					particlepuff(x*8,y*8,{7,6,5})
					addbox(tle,x,y)
					palt(0,false)
					palt(14,true)
					mset(x,y,ground_tile)--SET GROUND TYLE
					palt(0,false)
					palt(14,true)
				end
			end
			--ALL THE GOAL TYPES
			for t in all(goaltles) do
				if t==tle then
					addgoal(tle,x,y)
				end
			end
		end
	end
	--lock stuff
	if modlvl==0 then
		lock={0,0,0}
	end
	templvl=level--set the temp level to the actual level
		--set the state for the game
	_upd=upd_game 
	_drw=drw_level
end


-->8
--ui and juice

function shake()
	local shake_x=rnd(intensity) - (intensity /2)
	local shake_y=rnd(intensity) - (intensity /2)
  
	--offset the camera
	camera( shake_x + cam_x, shake_y + cam_y)
  
	--ease shake and return to normal
	intensity *= .9
	if intensity < .3 then 
		intensity = 0 
		camera(cam_x,cam_y)
	end
  end


function draw_scanline()
	--(_x,_y,_w,_h,_c)
	if showscan then
		rectfill2(cam_x+6,cam_y+yscan,116,1,3)

		showscan = false
	else
		showscan = true
		if yscan >= yscanend then
			yscan = yscanstart
		else
			yscan+=1
		end
		showscan=true
	end
end

function dofade()
 local p,kmax,col,k=flr(mid(0,fadeperc,1)*100)
 for j=1,15 do
  col = j
  kmax=flr((p+j*1.46)/22)
  for k=1,kmax do
   col=dpal[col]
  end
  pal(j,col,1)
 end
end


function fadeout(spd,_wait)
 if (spd==nil) spd=0.04
 if (_wait==nil) _wait=0
 repeat
  fadeperc=min(fadeperc+spd,1)
  dofade()
  flip()
 until fadeperc==1
 wait(_wait)
end

function checkfade()
	if fadeperc>0 then
		fadeperc=max(fadeperc-0.04,0)
		dofade()
	end
end


--menu
--(will move to ui when done)

function init_menu()
	music(0,10)
	frame=0
	msg={
		lines={},
		pos=0,
		rate=2,
		len=0
	     }
	     
	lines={
		"----------------------",
		">message from employer:",
		">your mission is the",
		">following,",
		">1) load user 42.42.10",
		">2) execute server scan",
		">3) break their ice",
		">3) delete all files",
		" .  .  .",
		">failure is not an option.",
	     }
	setmsg(lines)
	menu_timer = 200--used for menu animations
	menu_anim = true--used for menu animations

	_upd=upd_menu
	_drw=drw_menu
	
end

--might not use opening message
function updatemessage()
	if (frame%msg.rate==0) then
		msg.pos+=1
	end   
	frame+=1
end

function upd_menu()
	--updatemessage()
	--create particles
	for i=1,3 do
		local rx = rnd(104)--random place to start rain
		local ry = rnd(100)
		local age = rnd(50)+10 -- age of particle
		particlecode(8+rx,10+ry,age,{11,3,1})
	end

	if menucountdown<0 then
		if btnp(❎) then
			sfx(47)--start game
			music(-1)--stop music
			blinkspeed=1
			menucountdown=20			
		end
	else
		menucountdown-=1
		if menucountdown<=0 then			
			menucountdown=-1
			fadeout()
			part={}--clear particles
			init_hub()
		end
	end
end


function drw_menu()
	cls()
	-- drawmessage()
	draw_bas_ani()
	drawparts()--particles

	--draw splash image
	rrectfill2(30+menu_timer,27,69,24,6)--outline
	rrectfill2(31+menu_timer,28,67,22,0)--center
	sdrawgrid(103,32+menu_timer,31,8,2)--(stspr,_x,_y,_w,_h)
	
	--character
	rrectfill2(54-menu_timer,52,20,20,6)--outline
	rrectfill2(55-menu_timer,53,18,18,0)--center
	
	add_ani(p_ani,p_ani+3,16,4,60-menu_timer,58,false)--(_sa,_ea,_delay,_spd,_x,_y,_flp)

	--menu prompt
	rrectfill2(25+menu_timer,73,78,18,6)--outline
	rrectfill2(26+menu_timer,74,76,16,0)--center
	oprint8("press ❎ to start",30+menu_timer,80+sin(time()),blinkcolor,1)
	palt(0,false)
	palt(14,true)
	draw_bas_ani()
	palt(0,true)
	palt(14,false)

	if menu_anim then
		if menu_timer < 0 then
			menu_timer += 2
			if menu_timer == 0 then
				menu_anim = false
			end
		
		elseif menu_timer > -32 then
			menu_timer -= 4
		end
	end
end


function drawmessage()
	offset=0
	y=0

	if(frame%msg.rate==0 and msg.pos<msg.len) then
		if sfx1 then
		 	sfx(50)--type noise
		else
			sfx1=true
		end
	end
	for l in all(msg.lines) do
		off=msg.pos-offset
		if (off<0) then
			break
		end

		linepos=min(#l,off)
		if l[linepos]==" " then
			sfx1=false
		end
		out=sub(l,0,linepos)
		print(out,wnd.l+5,wnd.t+y+5,3)
		offset+=#l
		y+=6
	end
end

--might not use opening message
function setmsg(lines)
	msg.lines=lines
	msg.pos=0
	msg.len=0
	sfx1=false
	for l in all(lines) do
	 msg.len+=#l
	end
end

--hub

function sethubtext()
	local c = completedworlds
	if cmplist(c,{0,0,0}) then
		return hubtext[1]
	elseif cmplist(c,{1,0,0}) then
		return hubtext[2]
	elseif cmplist(c,{0,1,0}) then
		return hubtext[3]
	elseif cmplist(c,{0,0,1}) then
		return hubtext[4]
	elseif c[1]+c[2]+c[3]>1 then
		return hubtext[5]
	end


	return ""
end

function cmplist(_a,_b)
	for i=1,#_a do
		if _a[i]!=_b[i] then
			return false
		end
	end
	return true
end


function init_hub()

	hubsel=0
	hub_x, hub_y=0,8*(10+2*hubsel)
	hub_oy=0
	cam_x,cam_y=0,0
	camera(0,0)	
	msg={
		lines={},
		pos=0,
		rate=2,
		len=0
	     }
	wnd={l=9,t=40}        
	lines=sethubtext()
	setmsg(lines)

	_upd=upd_hub
	_drw=drw_hub
	music(24,100)--hub music
end

function hubinput()
	local _btn=getinput()
	if _btn==⬆️ then	--up
		prevhubsel=hubsel
		hubsel=(hubsel-1)%3
		sfx(52)--move cursor noise
		init_hubmove()
	elseif _btn==⬇️ then--down
		prevhubsel=hubsel
		hubsel=(hubsel+1)%3
		sfx(52)--move cursor noise
		init_hubmove()
	elseif _btn==5 then
		if completedworlds[hubsel+1]==1 then
			sfx(61)--cant choose world
		else
			intensity += shake_control--set the camera to shake
			for i=0,7 do
				particlepuff(26+i*10, hub_y+hub_oy,{6,5,1})	
				particleshatter(26+i*10, hub_y+hub_oy,{11})	
			end
			sfx(51)--select noise
			music(-1)
			level=hubsel*4+1
			_upd = upd_wait_for_particle
		end
	end
end

function upd_wait_for_particle()
	if #part <= 0 then
		level=11-- (used for debuging)
		init_level()
		fadeout()
	end
end

function init_hubmove()
	p_t=0
	--if we are going from 0->2 or 2->0
	if prevhubsel + hubsel == 2 then
		hub_oy=0
		p_t=1
	else
		hub_soy=16*(prevhubsel-hubsel)
		hub_oy=hub_soy
	end
	hub_y=8*(10+2*(hubsel))
	_upd = upd_hubcursor_loop
end

--used to move the cursors and shake them
function upd_hubcursor_loop()
	--slide
	p_t=min(p_t+0.4,1)
	hub_oy=hub_soy*(1-p_t)

	--particles
	particlerectangle(26, hub_y+hub_oy,80)
	
	
	
	--return hub control
	if p_t==1 then
		_upd = upd_hub
	end
	 
end

function upd_hub()
	updatemessage()
	hubinput()
end

function txtscroll(txt,x,y,w,spd,c)
	clip(x,y,w,5)--sets the clicking region of draw state
	local len=#txt*4+w
	local ox=(t/spd)%len
	print(txt,x+w-ox,y,c)
	clip()
     end

function drw_hub()
	cls(5)

	--news bar
	rectfill2(1*8-3,3,14*8+6,10,6)
	rectfill2(1*8-2,4,14*8+4,8,1)
	if completedworlds[2]==1 then --break news server
		print("bre0k1n8 n@w$: )(^$★+=_🐱🐱",1*8-2,6,7)
	else
		txtscroll(newstext,1*8-2,6,14*8+4,2,7)
	end
	
	

	print("optional",1*8,16,6)
	print("rewards",1*8,24,6)

	--draw acheivement
	for i=1,3 do
		rrectfill2(((i-1)*3+6)*8-1,2*8-2,2*8+2,17,15)--basic holder
		if acheivement[i]==1 then
			sdrawgrid(70+i*2,((i-1)*3+6)*8,14,2,2)
		elseif acheivement[i]==-1 then
			rrectfill2(((i-1)*3+6)*8-1,2*8-2,2*8+2,17,6)
		end
	end
	
	rectfill2(1*8-2,5*8-2,14*8+4,10*8+3,0)--pc background color
	map()
	--middle bar
	for i=0,13 do
		line((1+i)*8+1,64+4,(2+i)*8-2,64+4,3)
	end
	rectfill2(2,126,16*8-4,2,6)--lower pc (prevent showing in shake)
	--draw cursor
	add_ani(2,3,3,10, 8,hub_y+hub_oy, false)

	drawmessage()
	drawparts()--particles
	--draw rectangle
	for i=1,3 do
		local t =""
		local colr=3--dark green
		local ys=(10+2*(i-1))*8--10,12,14
		if i==(hubsel+1) then
			colr=11--light green (for text)
			rectfill2(26,hub_y+hub_oy,80,7,3)
		end

		if completedworlds[i]==1 then
			--draw server icon
			drawspr(28+i,16,ys,false)
			--draw red cross
			line(8*2,ys,8*3-1,ys+7,8)
			line(8*3-1,ys,8*2,ys+7,8)
			colr=5--dark grey (closed server)
			t=" [error 404]"
		else
			--draw bounce server icon
			drawspr(28+i,16,ys+sin(time()),false)
		end
		print(servertext[i]..t,26,ys+1,colr)
	end
	draw_bas_ani()
	drawgrids()
	
	draw_scanline()

	
	
end

-->8
--box and goal

--goal
function addgoal(tle,gx,gy) 
	local g={
		gf=tle,--tile normally
		x=gx,
		y=gy,
		flg=false
	}
	add(goal,g)
end

--box movement
function addbox(btle,bx,by) 
	local b={
		x=bx,
		y=by,
		ox=0,
		oy=0,
		tle=btle
	}
	add(box,b)
end

function checkbox(x,y)
	for b in all(box) do
 	if b.x==x and b.y==y then
 		return b
 	end
 end
 return false--NO BOX FOUND
end

function movebox()
	pushto=mget(slbx.x+slbx.dx,slbx.y+slbx.dy)
	--IF WALL
	slbx.mov=boxslide
	if fget(pushto,0) or checkbox(slbx.x+slbx.dx,slbx.y+slbx.dy) then
		sfx(61) -- wall noise
		slbx.mov=boxbump
		slbx.sox=slbx.dx*8
		slbx.soy=slbx.dy*8
		slbx.ox,slbx.oy=0,0
	else
		--PUSH BLOCK	
		slbx.x+=slbx.dx--SET NEW DESTINATION
		slbx.y+=slbx.dy
		slbx.sox=-slbx.dx*8--STARTING OFFSET
		slbx.soy=-slbx.dy*8
		slbx.ox,slbx.oy=slbx.sox,slbx.soy
		sfx(62)--push sound
		steps[level]+=1
	end
	p_t=0
	_upd=upd_box_loop
end

--LOOP UNTIL BOX FINISHES MOVING
function upd_box_loop()
	btn_buffer()
	p_t=min(p_t+.4,1)
	slbx.mov(p_t)
	particletrail(
	slbx.x*8+slbx.ox+4,
	slbx.y*8+slbx.oy+4)
	
	if p_t==1 then
		_upd=upd_game
		slbx=nil
	end
end

function boxslide(p_t)
	slbx.ox=slbx.sox*(1-p_t)
	slbx.oy=slbx.soy*(1-p_t)	
end

function boxbump(p_t)
	local tme=p_t
	--go back the second half of the animation
	if tme>0.5 then
		tme=1-p_t
	end
	slbx.ox=slbx.sox*tme
	slbx.oy=slbx.soy*tme
end

-->8
--particles

-- add a particle
function addpart(_x,_y,_dx,_dy,_type,_rad,_maxage,_col)
	local _p = {}
	_p.x=_x
	_p.y=_y
	_p.dx=_dx
	_p.dy=_dy
	_p.typ=_type
	_p.rad=_rad--radius of circle if used
	_p.orad=_rad--original radius
	_p.mage=_maxage
	_p.age=0
	_p.col=0--also sprite val
	_p.color_array=_col

	add(part,_p)
end
--4:19
-- spawn a trail
function particletrail(_x,_y)
	if rnd()<0.5 then
		local _ang=rnd()
		local _ox=sin(_ang)*2*.6
		local _oy=cos(_ang)*2*.6
		addpart(
			_x+_ox+4,
			_y+_oy+4,
			0,--dx
			0,--dy
			0,--type
			0,--radius
			15+rnd(10),
			{11,3,1}
		)
	end
end

function particlecode(_x,_y,_age,_col)
	for i=1,10 do
		local _ang=rnd()
		local _ox=sin(_ang)*2*.6
		local _oy=cos(_ang)*2*.6
		addpart(
			_x+_ox+4,
			_y+_oy+4,
			0,--dx
			0,--dy
			1,--type
			0,--radius
			_age,--age
			_col
		)
	end
end

function particlerectangle(_x,_y,_w)
	addpart(
		_x,
		_y,
		0,
		0,
		3,--type
		_w,--radius/width
		5,--age
		{11,3,1}
	)
end

function particlepuff(x,y,col)
	for i=0,10 do
		local _ang=rnd()
		local _dx=sin(_ang)*2
		local _dy=cos(_ang)*2
		addpart(
			x+4,
			y+4,
			_dx,--dx
			_dy,--dy
			2,--type
			rnd(5),--radius
			10,--age
			col
		)
	end
end

--place brick in slot
function particleshatter(x,y,col)
	for i=0,10 do
		local _ang=rnd()
		local _dx=sin(_ang)*1
		local _dy=cos(_ang)*1
		addpart(
			x+4,
			y+4,
			_dx,
			_dy,
			1,--type
			0,--radius
			15,--age
			col--,3,1}
		)
	end

end


function updateparts()
	local _p
	for i=#part,1,-1 do
		_p=part[i]
		_p.age+=1
		local agperc=_p.age/_p.mage--AGPERC 0->1
		if _p.age > _p.mage then
			del(part,part[i])
		else
		 -- change colors
			if #_p.color_array==1 then
				_p.col = _p.color_array[1]
			end
			--FLR(PERCENT*#ARRAY) = THE INDEX OF THE COLOR
			local _ci =1+flr(agperc*#_p.color_array)
			_p.col = _p.color_array[_ci]
		end
		
		--shatter particle
		if _p.typ == 1 then
		--	_p.dy+=0.1
		end
		
		--puff particle
		if _p.typ == 2 then
			local _ci = 1-agperc
			_p.rad = _ci*_p.orad
			--friction
			_p.dx=_p.dx*0.84
			_p.dy=_p.dy*0.84
			-- _p.rad -= 0.4
			-- if _p.rad < 0 then
			-- 	_p.r=0
		end

		--move particle
		_p.x+=_p.dx
		_p.y+=_p.dy
	end
end

function drawparts()
	for i=1,#part do
		_p=part[i]
		-- pixel particle
		if _p.typ == 0 or _p.typ == 1 then
			pset(_p.x,_p.y,_p.col)
		elseif _p.typ == 2 then
			circfill(_p.x,_p.y,_p.rad,_p.col)
		elseif _p.typ == 3 then--rectangle particle
			rectfill2(_p.x,_p.y,_p.rad,7,_p.col)
		end
	end
end

__gfx__
0000000000000000000000000000000000d6660000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4ee4eeeeeebbbbbbbb0000000000000000
0000000000000000000030000000000000d76600dddddddde55555eeee6ee6eee656565eeeddddeeee5555eeee5554ee4e4eeeeeb333333b0000000000000000
0070070000000000000003000000000000d6760066666666e522225ee555555ee777775eed1111dee586685ee555450ee49eeeeeb333333b0000000000000000
0007700000000000000000300000000000d7670066666666e522225ee522225ee7ddd75eed1dd1dee565565ee555550eeee9eeeeb333333b0000000000000000
0007700000000000000003000000000000d676006b555556e555555ee544445ee777775eed1dd1dee575575ee555550eeeee9eeeb333333b0000000000000000
0070070000000000000030000000000000d6670066666666e599995ee555555ee7ddd75eed1111de55755755e555550eeeeae9eeb333333b0000000000000000
0000000000000000000000000000000000d6660000000000e5aaaa5eee6ee6eee77777eeeeddddee5e5ee5e5ee0000eeeeeeae9eb333333b0000000000000000
0000000000000000000000000000000000d6660000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeae9bbbbbbbb0000000000000000
dddddd5e2222225e00666666666666666666660066666666e464464ee444444e65555556eeeeedddeeeeeeeeeeeeeeee5555555e066666600d0000d000000000
dddddd5e2222225e00666666666666666666660066666686464444644444444466666666eeeeed8dee2122eeee5555ee6666666e06bbbb600d0000d006666660
dddddd5e2222225e00666666666666666666660066666a7e464444644644446466c6cc66dddddddded12212ee559955e6655566e06bbbb600d0000d006333360
dddddd5e2222225e006666666666666666666600666666c644644644445555446c6666c6d555555de122122e599aa995e5e5e5ee06bbbb600d0000d006333360
dddddd5e2222225e0066666666666666666666006666666644644644445555446c6666c6dddddddded11221e5aaaaaa55566655e0dddddd00d0550d00666b860
dddddd5e2222225e00666dddddddddddddd66600dddddddd446446444644446466cc6c66eeeeeeeee122212e599999956666666e066666600566665006655660
5555555e5555555e00666d000000000000d6660000000000455555544444444466666666eeeeeeeeed22122e5aaaaaa55555555e065555600566b85006666660
eeeeeeeeeeeeeeee00666d000000000000d6660000000000e555555ee444444ee666666eeeeeeeeeed21221e55555555eeeeeeee066666600555555005555550
000000004444445e00666d0000666d0000d66600eeeee66666eeeeeeeeeeeee6eeeeeeeeeeeeeee6eeeeeeeeeeeeeee6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000000004444445e00666d0000667d0000d66600eee665555566eeeeeeeeee656eeeeeeeeeeeee666eeeeeeeeeeeee656eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000000004444445e00666d0000676d0000d66600ee655ddddd556eeeeeeee65d66eeeeeeeeeeee666eeeeeeeeeeee66d56eeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000000004444445e00666d0000767d0000d66600e65dddd6dddd56eeeeee65ddd66eeeeeeeeeee666eeeeeeeeeee66ddd56eeeee4eeeeeeeeeeeeeeeeeeeeeee
000000004444445e00666d0000676d0000d66600e65ddd6d6ddd56eeeeee65ddd66eeeeeeeeeee666eeeeeeeeeee66ddd56eeeee4eeeeeeeeeeeeeeeeeeeeeee
000000004444445e00666d0000766d0000d6660065ddd6ddd6ddd56eeee65dd6dd66eeeeeeeeee66eeeeeeeeeee66dd6dd56eeee4eeeeeeeeeeeeeeeeeeeeeee
000000005555555e00666d0000666d0000d6660065ddd66dd6ddd56eeee65dd6dd66eeeeeeeeee66eeeeeeeeeee66dd6dd56eeee54eeeeeeeeeeeeeeeeeeeeee
00000000eeeeeeee00666d0000666d0000d6660065ddd666d6ddd56eeee65dd6dd66eeeeeeeeee66eeeeeeeeeee66dd6dd56eeee54eeeeeeeeeeeeeeeeeeeeee
9999995eeeeeeeee00666d000000000000d6660065ddd666d6ddd56eeee65dd6dd66eeeeeeeeee66eeeeeeeeeee66dd6dd56eeee54eeeeee666ddddddddddddd
9999995eeeeeeeee00667dddddddddddddd7660065ddd6ddd6ddd56eeee65dd6dd66eeeeeeeeeee6eeeeeeeeeee66dd6dd56eeeee54eeeeedddddd555555555d
9999995eeeeeeeee006667666666666666766600e65ddd6d6ddd56eeeeee65ddd66eeeeeeeeeeee66eeeeeeeeeee66ddd56eeeeee544444e55555deeeeeeee5d
9999995eeeeeeeee006666666666666666666600e65dddd6dddd56eeeeee65ddd66eeeeeeeeeeee66eeeeeeeeeee66ddd56eeeeee545554eeeee5deeeeeeee5d
9999995eeeeeeeee006666666666666666666600ee655ddddd556eeeeeeee65d66eeeeeeeeeeee666eeeeeeeeeeee66d56eeeeeee45eeee4eeee5deeeeeeee5d
9999995eee3eeeee006666666666666666666600eee665555566eeeeeeeeee666eeeeeeeeeeeee666eeeeeeeeeeeee666eeeeeeee45eeee4eeee5deeeeeeee5d
5555555eeeeeeeee000000000000000000000000eeeee66666eeeeeeeeeeeee6eeeeeeeeeeeeeee6eeeeeeeeeeeeeee6eeeeeeee45eeeeee4eee5deeeeeeee5d
eeeeeeeeeeeeeeee000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee45eeeeee4eee5deeeeeeee5d
e55555555555555ee59999999999995ee59999999999995ee55555555555555e0000000000000000000066666660000000000000000000000000000000000000
e59999999999995ee59999999999995ee59999999999995ee53333333333335e000dddddd00000000066ddd8ddd6600000000000000000000000000000000000
e59999999999995ee59999999999995ee59999999999995ee53333333333335e0dd555555dd0000006dddd888dddd60000666666666600000000000000000000
e59999999999995ee59999999999995ee59999999999995ee55335555553355ed5555555555d00006dddd8d8d8dddd6006666666666661000000000000000000
e59999999999995ee59999999999995ee55995555559955eee5335eeee5335eeddd555555ddddd006dddd8d8dddddd6006633333333661000000000000000000
e59999999999995ee55995555559955eee5995eeee5995eeee5555eeee5555eedddddddddddd1dd06dddd8d8dddddd6006633333333661000000000000000000
e55995555559955eee5995eeee5995eeee5555eeee5555eeeeeeeeeeeeeeeeeedddbddddbddd01dd6dddd8d8d8dddd6006633333333661000000000000000000
ee599559955995eeee555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddddbddbdddd001d06dddd888dddd6100663b333333661000000000000000000
e55555599555555eeeeeee5995eeeeeeeeeeee5555eeeeeeeeeeeeeeeeeeeeeeddddbbbbdddd000d0066ddd8ddd661000663bbbb3d3661000000000000000000
e59999999999995ee55555599555555eeeeeee5995eeeeeeeeeeee5555eeeeeedddbdbbdbddd00dd000066666661100006633333333661000000000000000000
e59999999999995ee59999999999995ee55555599555555eeeeeee5335eeeeeedddbddddbddd0dd1000066666661000006666666666661000000000000000000
e59999999999995ee59999999999995ee59999999999995ee55555533555555eddddbddbdddddd10000066666661000006665666668661000000000000000000
e59999999999995ee59999999999995ee59999999999995ee53333333333335edddddddddddd1100000066666661000006655566686661000000000000000000
e59999999999995ee59999999999995ee59999999999995ee53333333333335e1dddddddddd10000000066111161000006665666666661000000000000000000
e55555555555555ee55555555555555ee55555555555555ee55555555555555e01dddddddd100000000066000161000000666666666610000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0011111111000000000066000161000000111111111100000000000000000000
eeee555eeeee555eeeee555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000001ccc000000000000000000000000000000000000000000000000000000000000000
eeeeb555eeeeb555eeee3555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00001c111c00000000000000000000000b300000b3000000000000000000000000000000
eee3b565eeeb3565eeebb5655eeeeeee5eeeeeee5eeeeeee5eeeeeee0001c1000100000000000000000000000b300000b3000000000000000000000000000000
eeeb3566eeebb566eee3b5665eeeeeee5eeeeeee5eeeeeee5eeeeeee0001c0000000000000000000000000000b300000b3000000000000000000000000000000
eeebb566eee3b566eeeb356655eeeeee55eeeeee55eeeeee55eeeeee0001c0000000000000000000000000000b300000b3000000000000000000000000000000
eee3b566eeeb3566eeebb56665ee55ee65ee55ee65eeccee65ee55ee0001c000000000000001c001c000000000b3000b30000000000000000000000000000000
eeee3566eeeeb566eeeeb56665e5ee5e65ecee5e65e5ee5e65e5eece00001c00000000000001c01c0000000000b3000b30000000000000000000000000000000
eeee5555eeee5555eeee5555555eeee555ceeee5555eeee5555eeeec000001c0000000000001c1c00000000000b3000b30000000000000000000b30000000000
ebeeeebeeebeebeeebeeeebeeeeeeeeeeeebeebeeeeeeeeeeeeeeeee0000001c000001cc0001c1c00001cc00000b300b300b300b30000000000b3b3000000000
eebeebeeebbbbbbeeebeebeeebeeeebeeeeeeeeeeebeeebeeeeeeeee00000001c0001c01c001cc00001c01c0000b30b3000000b3b30b30b300b3000000000000
ebbbbbbeeb0303beebbbbbbeeebeebeeeeebbbbeeeebebeeeeeeeeee00000001c001c001c001cc0001c0001c000b30b3000b30b3000b30b300b3000000000000
eb0303beeb0000beeb0303beebbbbbbeeeeb03beeebbbbbeeeebbeee000000001c01c0001c01c1c001c0001c0000b0b3000b30b3000b30b3000b300000000000
eb0000beeebbbbeeeb0000beeb0303beeeeb00beebebbbebeeebbeee01c000001c01c0001c01c1c001c0001c0000b0b3000b30b3000b30b30000b30000000000
bebbbbebbeeeeeebbebbbbebbebbbbebeebebbebebeeeeebeeeeeeee001c00001c01c001c001c01c01c001c000000b30000b30b3000b30b300000b3000000000
beeeeeebbeeeeeebebeeeebebeeeeeebeebeeeebeebbebbeeeeeeeee0001ccccc0001ccc0001c001c01ccc0000000b30000b30b30000bb3b30bbb30000000000
ebbeebbeebeeeebeeebeebeeebbeebbeeeebeebeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000001010000000000000000000001010101010100000000000000000000000101010100000000000000000000000100010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313151400121313131313131313131313131315140012131313131313131313131313131514001213131313131313131313131313151400121313131313131313131313131315140012131313131313131313131313131514001213131313131313131313131313151400000000000000000000
2300000000000000000000000000000400220000001010101010101010101000240022000000000000000000000000000024002200000000000000000000000000002400220000001010101010000000000000240022000000000000000000000000000024002200000000000000000000000000002400000000000000000000
2200000000000000000000000000002400220000001031313131313131311000240022000010101010100000000000000024002200000000101010101010000000002400220000001031313110101000000000240022000011111111111111110000000024002200000011111111111100000000002400000000000000000000
2200000000000000000000000000002400220000101031101010101010311000240022000010313131101000000000000024002200000000101616161010000000002400220000001031103131311000000000240022001111313111313131110000000024002200000011313131311111000000002400000000000000000000
2200000000000000000000000000002400221010103131101010313110311000240022101010311007311010101010100024002200000000100631103110000000002400220000001031063110311000000000240022111131313131310931110000000024002200111111311911313111000000002400000000000000000000
2200000000000000000000000000002400221031310731310731310717171000240022103131311031313131171717100024002200000000103106313110000000002400220000001010100610311000000000240022113119193111093111110000000024002200113131190919113111000000002400000000000000000000
2200000000000000000000000000002400221010103131101031313110101000240022103131310731071031101010100024002200000000103131063110000000002400220000001010313106311000000000240022113119311131093131111111110024002200113119090909313111000000002400000000000000000000
2200000000000000000000000000002400221010101010101031313131171000240022101010101010313131100000000024002200000000101010313110000000002400220000000010313131100000000000240022113119111131311131313131110024002200111111311131311111000000002400000000000000000000
2200000000000000000000000000002400220000000000001010101010101000240022000000000010101010100000000024002200000000000010313110000000002400220000000010101031100000000000240022111111111131313131310931110024002200000011313131111100000000002400000000000000000000
2200000000000000000000000000002400220000000000000000000000000000240022000000000000000000000000000024002200000000000010101010000000002400220000000000103116311000000000240022000000001131311111111111110024002200000011111111110000000000002400000000000000000000
2200000000000000000000000000002400220000000000000000000000000000240022000000000000000000000000000024002200000000000000000000000000002400220000000000103116161000000000240022000000001111111100000000000024002200000000000000000000000000002400000000000000000000
3233333333333333333333333333053400323333333333333333333333333305340032333333333333333333333333330534003233333333333333333333333333053400323333333333333333333333333305340032333333333333333333333333333334003233333333333333333333333333053400000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313151400121313131313131313131313131315140012131313131313131313131313131514001213131313131313131313131313151400121313131313131313131313131315140012131313131313131313131313131514001213131313131313131313131313151400000000000000000000
2200000000001111111111000000002400220000001111111111111100000000240022000030303030303000000000000024002200000030303030300000000000002400220000000000100010000000000000240022000000000010000010100000000024002200000000000000000000000000002400000000000000000000
2200000000001131313111000000002400220000001131313131311111000000240022000030313131313000000000000024002200000030313131300000000000002400220b000000001000000000000000002400220c0000000010000000000000000024002200000000000000000000000000002400000000000000000000
22000000111111310831110000000024002200000011310818081831110000002400220000303130301a3030303000000024002200303030313031303000000000002400221b000000001000000000000000002400221c0000000010000000000000000024002200000000000000000000000000002400000000000000000000
22000000113131310831110000000024002200000011311808180831110000002400220000303131310a31313130000000240022003031310a1a0a313000000000002400220000000000100000000000000000240022000000000010000000000000000024002200000000000000000000000000002400000000000000000000
22000000113131310831110000000024002200000011310818081831110000002400220000303030301a30303130000000240022003031301a3031313000000000002400220000000000100000000000000000240022000000000010000000000000000024002200000000000000000000000000002400000000000000000000
22000000111111311811110000000024002200000011311808180831110000002400220000303131310a31313130000000240022003031310a1a0a313000000000002400220000000000000000000000000000240022000000000000000000000000000024002200000000000000000000000000002400000000000000000000
22000000000011311811000000000024002200000011111111111111110000002400220000303130301a303030300000002400220030303031301a303000000000002400220000000000000000000000000000240022000000000000000000000000000024002200000000000000000000000000002400000000000000000000
22000000000011311811000000000024002200000000000000000000000000002400220000303131310a3131300000000024002200000030313131300000000000002400220000000000000000000000000000240022000000000000000000000000000024002200000000000000000000000000002400000000000000000000
2200000000001111111100000000002400220000000000000000000000000000240022000030303030313131300000000024002200000030303030300000000000002400220000000000000000000000000000240022000000000000000000000000000024002200000000000000000000000000002400000000000000000000
2200000000000000000000000000002400220000000000000000000000000000240022000000000030303030300000000024002200000000000000000000000000002400220000000000000000000000000000240022000000000000000000000000000024002200000000000000000000000000002400000000000000000000
3233333333333333333333333333053400323333333333333333333333333305340032333333333333333333333333330534003233333333333333333333333333053400323333333333333333333333333305340032333333333333333333333333330534003233333333333333333333333333053400000000000000000000
__sfx__
901e002027745277152771527715277152772527725277153071530745307353071530745307452c7352c7252c7152c7352c7352c7252c7352c7252c7352c7452c7252c7352c7452c7452c7452c7452c72500000
901e00202772527745277152771527715277152772527725277153071530745307353071530745307452c7352c7252c7152c735297352972529735297252973529745297252b7352c7452c7452c7452b7452b725
001e00200c0433f205246150c0053f10500005246150c0050c0053f300246150c0050c00500005246150c0430c0433f500246150c0050c00500005246150c0050c0003f500246150c0050c00500005246150c005
001e00200c0433f205246150c0053f10500005246150c0050c0053f300246150c0050c00500005246150c0050c0433f500246150c0050c00500005246150c0430c0433f41524615256152a6152c6153061532615
001e00000c0003f200246150c0003f11500000246150c0000c0003f300246150c0000c0000c615246150c0000c0003f515246150c0000c00000000246150c0000c0003f415246150c61518615246152461530615
301e00000313500105031050313503105031050313503105031350310503105031350310503105031350310500135031050010500135001050010500135001050013500105001050013500105001050013500105
001e00000313500105031050313503105031050313503105031350310503105031350310503105031350310500135031050010500135001050013500105001050013500135001050013500105001050013500105
641e002027012270122701227012270122b01233012330123301230012300122e0122e0122b0122b012290122e0122e0022e0122e0022e0122701226012180121d012220122e0122b0122b012290122901229012
641e00002b0122b0122b0122b0122e0122701227012270122701230012300122e0122e0122b012290122701224012220121f0121d0121b0121b012180121f0121f0121f0121f0121f0121f0121f0122401224012
001000002400024000240002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400200005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200000
011400000305203052030520305203052030520305203052030520305203052030520305203052030520305203052030520305203052030520305203052030520305203052030520305203052030520305203052
c514002002000020002e0122c0122c0122a2122a21227200272122c3002c3002a3002c4002a400274002c400273122c3122c3122a3122c4122a412274122c4002a4002740002000020002c4122a4122741200000
cd1400202c3002a3122a3002a3102c2112c3102c3122a300273002e3122c3002e3122c3002a300273002c300272002c2002c2002a2102c2112a210273122c3002a30027300023002730032000320003200031000
911400200c0330c0000c0030c0050c0430c0000c0000c0050c0430c0000c0000c0050c0330c0000c000246000c0330c0000c0000c0050c0530c0000c0000c0050c0333f2050c0000c0050c033000050c6230c005
771400201b60500605006053f6153f615006051b605006051b60500605371003b1003b100006051b605006051b60000605371153b1151b605006051b605006051b6001b6001b6001b600006051b6141b6141b614
791400203201232012320153201232012320153301133012330123301233012330123301531000310003100031000320003100031000310003200032000320003201531011310153201531011310123101231015
791400203201232012320153201232015330113301233012330123301233012330123300031000310003100031012310123101532011310153201131012310123200031000310003201531011310123101231015
4b14002032000320003200032000320003200033000330003300033000330000f0451102513055150451600531004150451704519034246242462424624246242460031000310003200031000310003100031000
011400200c0003f20524615246003f10500005246150c0050c0053f30024615246000c00500005246150c0000c0003f500246150c0050c00524600246150c0050c0003f500246150c0050c00500005246150c005
910c00200c0530c0000c0030c0050c0530c0000c0000c0050c0530c0000c0000c0050c0530c0000c000246000c0530c0000c0000c0050c0530c0000c0000c0050c0533f2050c0000c0050c053000050c6000c005
490c00200c0050c0050c0050c0050c6450c0050c0050c0050c0050c0050c0050c0050c6450c0050c005246050c0050c0050c0050c0050c6050c0050c0050c0050c6450c6050c6050c6450c6050c6050c6450c645
490c00200c0050c0050c0050c0050c6450c0050c0050c0050c0050c0050c0050c0050c6450c0050c005246050c0050c0050c0050c0050c6450c0050c0050c0050c0053f2050c0050c0050c645000050c6450c005
9f0c0020131250e1250e1250e1250e1250e1250e1250e125131250e1250e1250e1250e1250e1250e1250e125131250e1250e1250e1250e1250e1250e1250e125131250e1250e1250e1250e1250e1250e1250e125
9f0c00201012513125131251312513125131251312513125101251312513125131251312513125131251312510125131251312513125131251312513125131251012513125131251312513125131251312513125
010c00200005500055000550005500055000550005500055000550005500055000550005500055000550005500055000550005500055000550005500055000550005500055000550005500055000550005500055
311e00000310000100031000310003100031000310003100031000310003100031000310003100031000010000100001000010000100001000010000100001000010000100001000010000100001000010000000
001e00200c0433f205246150c0053f10500005246150c0050c0053f300246150c0050c00500005246150c0430c0433f500246150c0050c00500005246150c0050c0003f500246150c0050c00500005246150c005
301e00000310003135001050313503100031350310003135031000313500105031350310003135031000313500100001350010500135001050013500105001350010000135001050013500105001350010500135
301e000003102034310f0421203214042031021404203102140001404200102120320f0420f04203102031020e000120320f0420f042120001b0421b0321b0221b0321b041001020000000000000000000000102
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d52c00000c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410f0410f0410f0410f0410f0410f0410f0410f0410f0410f0410f0410f0410f0410f0410f0410f041
d52c00000c0400c0410c0410c0410c0420c0420c0420c0410c0410c0410c0410c0410c0410c0410c0410c04105041090410904109041090410904209042090420904209041090410904109041090410904109041
0010000028615000002a600000002a615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6a05000018010160101603018050180501b0501d050220402403029020300503a05014600176001b600206002a600396001310013100191001e100241002c1000000000000000000000000000000000000000000
003300003005000000000000000033556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0500003c64038640366502f6502c6500965008650086500a6500d650106501265014650176501b650206502a650396500000000000000000000000000000000000000000000000000000000000000000000000
490100001b51006540065401953018530005000050000500045000350002500015000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
71100000290551e0001e0000000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
711000001d0551e0001e0000000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000100000e0000f000100001100014000170001b0001e0002200024000170000a000010001c0001c0001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000000022905227052290522c0522c0520000200002000020000200002000020000200002010020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
1a0100002700027000270002700024000200001b000140003c0001400017000190001d0002100023000280002d000000000000000000000000000000000000000000000000000000000000000000000000000000
900100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002110015100271000f6000f6001c600196001760016600156000f6000c6000960007600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002e00029000230001f0001c000180001700015000140001300012000110001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9101000037650376402164021630216202262022610316003160031600316002a6002c6000b6000d600226001f6001c600186001660013600106000e6000c6000a60008600066000560000600006000060000600
4a0200000861006610056200462004630046200461004610056100561006640076300763008620096200b6200c6200d6100f62011620136301563017640186401a6301d6301f630236302765029660266702e670
000100001f2401c24017240122300e2300c2100a21008210062100521004250032400525002200042000520004200032000320002200022000220002200012000020000200002000020000200002000020000200
480100003006030060290402904016030160302b0202b020300002f0001a0001d000200000d0000b0001d0001e0002000022000190001300016000190001e0002400027000080000000000000000000000000000
900100002d0302403019010120100d0100b0100901007010060100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00054643
00 01064844
00 00054643
00 01064844
00 00050702
00 01060802
00 00050702
00 01060803
02 41064145
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424145
00 41424344
01 40451b1c
00 40451b1c
00 401d1b1c
00 40451b1c
00 4a4e5052
00 4b4e5152
00 41424344
00 41424344
01 20424344
02 21424344
00 41424344
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
01 14161957
00 14151957
00 14161917
00 14161917
00 14161918
00 14151918
00 14161917
00 14161917
00 14161918
00 14161918
00 54551918
02 54161918
00 41424344
00 41424145
00 41424145
00 41424145
00 41424344
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145

