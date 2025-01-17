package en;
import haxe.ds.Vector;

/**
	PlayerBase is an Entity with some extra functionalities:
	- user controlled (using gamepad or keyboard)
	- falls with gravity
	- has basic level collisions
	- some squash animations, because it's cheap and they do the job
**/

class PlayerBase extends Entity {

	var ca : ControllerAccess<GameAction>;
	var speed = .025;
	var walkSpeed = new Vector<Float>(2);
	var walkDown  : h2d.Anim;
	var walkUp    : h2d.Anim;
	var walkLeft  : h2d.Anim;
	var walkRight : h2d.Anim;

	// This is TRUE if the player is not falling
	// var onGround(get,never) : Bool;
	// 	inline function get_onGround() return !destroyed && vBase.dy==0 && yr==1 && level.hasCollision(cx,cy+1);

	public function new() {
		super(5,5);

		// Start point using level entity "PlayerStart"
		var start = level.data.l_Entities.all_PlayerStart[0];
		if( start!=null )
			setPosCase(start.cx, start.cy);


		// Misc inits
		vBase.frict = .7;

		// Camera tracks this
		camera.trackEntity(this, true);
		camera.clampToLevelBounds = true;

		// Init controller
		ca = App.ME.controller.createAccess();
		ca.lockCondition = Game.isGameControllerLocked;

		// Sprites
		walkUp    = Assets.getCharAnim(spr, 4, 0);
		walkRight = Assets.getCharAnim(spr, 5, 0);
		walkDown  = Assets.getCharAnim(spr, 6, 0);
		walkLeft  = Assets.getCharAnim(spr, 7, 0);
		walkDown.visible = true;
	}


	override function dispose() {
		super.dispose();
		ca.dispose(); // don't forget to dispose controller accesses
	}


	/** X collisions **/
	override function onPreStepX() {
		super.onPreStepX();

		// Right collision
		if( xr > 0.75 && level.hasCollision(cx+1,cy) )
			xr = 0.75;

		// Left collision
		if( xr < 0.25 && level.hasCollision(cx-1,cy) )
			xr = 0.25;
	}


	/** Y collisions **/
	override function onPreStepY() {
		super.onPreStepY();

		// Land on ground (example)
		if( yr>1 && level.hasCollision(cx,cy+1) ) {
			// setSquashY(0.5);
			// vBase.dy = 0;
			// vBump.dy = 0;
			yr = 1;
			// ca.rumble(0.2, 0.06);
			// onPosManuallyChangedY();
		}

		// Ceiling collision
		if( yr<0.25 && level.hasCollision(cx,cy-1) )
			yr = 0.25;
	}


	/**
		Control inputs are checked at the beginning of the frame.
		VERY IMPORTANT NOTE: because game physics only occur during the `fixedUpdate` (at a constant 30 FPS),
		no physics increment should ever happen here!
		What this means is that you can SET a physics value
		(eg. see the Jump below),
		but not make any calculation that happens over multiple frames
		(eg. increment X speed when walking).
	**/
	override function preUpdate() {
		super.preUpdate();

		walkSpeed = new Vector<Float>(2);

		// if( onGround )
		// 	cd.setS("recentlyOnGround",0.1); // allows "just-in-time" jumps

		// Jump
		// if( cd.has("recentlyOnGround") && ca.isPressed(Jump) ) {
		// 	vBase.dy = -0.85;
		// 	setSquashX(0.6);
		// 	cd.unset("recentlyOnGround");
		// 	fx.dotsExplosionExample(centerX, centerY, 0xffcc00);
		// 	ca.rumble(0.05, 0.06);
		// }

		// Ping
		if (ca.isReleased(Jump))
			hud.notify('ping');

		// Walk
		if (!isChargingAction()) {
			if (ca.getAnalogDist2(MoveLeft, MoveRight) > 0)
				walkSpeed[0] = ca.getAnalogValue2(MoveLeft, MoveRight);
			if (ca.getAnalogDist2(MoveUp, MoveDown) > 0)
				walkSpeed[1] = ca.getAnalogValue2(MoveUp, MoveDown);
		}
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		// Gravity
		// if( !onGround )
		// 	vBase.dy+=0.05;

		// Apply requested walk movement
		if (walkSpeed[0] != 0 || walkSpeed[1] != 0) {
			// apply physics
			vBase.addXY(
				walkSpeed[0] * speed,
				walkSpeed[1] * speed
			);
			// play animation
			setWalking(true);
			if (Math.abs(walkSpeed[1]) > Math.abs(walkSpeed[0])) {
				if (walkSpeed[1] < 0)
					setDirection(MoveUp);
				else
					setDirection(MoveDown);
			}
			else {
				if (walkSpeed[0] > 0)
					setDirection(MoveRight);
				else
					setDirection(MoveLeft);
			}
		}
		else setWalking(false);
	}

	function setDirection(direction:GameAction) {
		walkUp.visible = direction == MoveUp;
		walkRight.visible = direction == MoveRight;
		walkDown.visible = direction == MoveDown;
		walkLeft.visible = direction == MoveLeft;
	}

	function setWalking(isWalking:Bool) {
		pauseAndReset(walkUp, !isWalking);
		pauseAndReset(walkRight, !isWalking);
		pauseAndReset(walkDown, !isWalking);
		pauseAndReset(walkLeft, !isWalking);
	}

	function pauseAndReset(anim:h2d.Anim, pause:Bool) {
		anim.pause = pause;
		if (pause)
			anim.currentFrame = 0;
	}
}
