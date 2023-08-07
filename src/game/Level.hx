class Level extends GameChildProcess {
	/** Level grid-based width**/
	public var cWid(default,null): Int;
	/** Level grid-based height **/
	public var cHei(default,null): Int;

	/** Level pixel width**/
	public var pxWid(default,null) : Int;
	/** Level pixel height**/
	public var pxHei(default,null) : Int;

	public var data : World_Level;
	public var enBuffer = new h2d.Object();

	public var marks : dn.MarkerMap<LevelMark>;
	var invalidated = true;

	public function new(ldtkLevel:World.World_Level) {
		super();

		createRootInLayers(Game.ME.scroller, Const.DP_BG);
		data = ldtkLevel;
		cWid = data.l_Collisions.cWid;
		cHei = data.l_Collisions.cHei;
		pxWid = cWid * Const.GRID;
		pxHei = cHei * Const.GRID;

		marks = new dn.MarkerMap(cWid, cHei);
		for(cy in 0...cHei)
		for(cx in 0...cWid) {
			if( data.l_Collisions.getInt(cx,cy)==1 )
				marks.set(M_Coll_Wall, cx,cy);
		}
	}

	override function onDispose() {
		super.onDispose();
		data = null;
		marks.dispose();
		marks = null;
	}

	/** TRUE if given coords are in level bounds **/
	public inline function isValid(cx,cy) return cx>=0 && cx<cWid && cy>=0 && cy<cHei;

	/** Gets the integer ID of a given level grid coord **/
	public inline function coordId(cx,cy) return cx + cy*cWid;

	/** Ask for a level render that will only happen at the end of the current frame. **/
	public inline function invalidate() {
		invalidated = true;
	}

	/** Return TRUE if "Collisions" layer contains a collision value **/
	public inline function hasCollision(cx,cy) : Bool {
		return !isValid(cx,cy) ? true : marks.has(M_Coll_Wall, cx,cy);
	}

	/** Render current level**/
	function render() {
		// Placeholder level render
		root.removeChildren();

		var ground = new h2d.TileGroup();
		data.l_LevelAuto.render(ground);
		data.l_RoadAuto.render(ground);
		data.l_Buildings.render(ground);

		var buildingFx = new h2d.TileGroup();
		data.l_BuildingEffects.render(buildingFx);

		root.addChildAt(ground, Const.DP_BG);
		root.addChildAt(enBuffer, Const.DP_MAIN);
		root.addChildAt(buildingFx, Const.DP_FRONT);
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}