Birds =
{
	type = "Birds",
	MapVisMask = 0,
	ENTITY_DETAIL_ID=1,

	Properties =
	{
		Flocking =
		{
			bEnableFlocking = 1,
			FieldOfViewAngle = 250,
			FactorAlign = 3,
			FactorCohesion = 2,
			FactorSeparation = 1,
			AttractDistMin = 1,
			AttractDistMax = 20,
		},
		Movement =
		{
			HeightMin = 10,
			HeightMax = 20,
			SpeedMin = 1,
			SpeedMax = 3,
			FactorOrigin = 1,
			FactorHeight = 0.4,
			FactorAvoidLand = 100,
			FactorTakeOff = 10,
			MaxAnimSpeed = 1,
			FlightTime = 20,
			LandDecelerationHeight = 5,
		},
		Ground =
		{
			FactorAlign = 0,
			FactorCohesion = 3,
			FactorSeparation = 0.1,
			FactorOrigin = 10,
			WalkSpeed = 0,
			HeightOffset = 0,
			WalkToIdleDuration = 3.0,
			OnGroundIdleDurationMin = 1.6,
			OnGroundIdleDurationMax = 3.2,
			OnGroundWalkDurationMin = 4.0,
			OnGroundWalkDurationMax = 6.0,
		},
		Boid =
		{
			nCount = 10,
			object_Model = "objects/characters/animals/birds/pigeon/pigeon_lf.chr",
			--Size = 1,
			--SizeRandom = 0,
			gravity_at_death = -9.81,
			Mass = 10,
			bInvincible = false,
		},
		Options =
		{
			bFollowPlayer = 0,
			bNoLanding = 0,
			bStartOnGround = 1,
			bObstacleAvoidance = 1,
			VisibilityDist = 200,
			AnimationDist = 0,
			bActivate = 1,
			Radius = 4,
			bSpawnFromPoint = 0,
		},
	},

	Animations =
	{
		"fly_loop",		-- fly
		"take_off",		-- take off
		"walk_loop",	-- walk
		"idle_loop",	-- idle 1,
		"landing"		-- landing
	},

	Editor =
	{
		Icon = "Bird.bmp"
	},
	params={x=0,y=0,z=0},
}

-------------------------------------------------------

function Birds:OnSpawn()
	self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0);
  self:SetFlagsExtended(ENTITY_FLAG_EXTENDED_NEEDS_MOVEINSIDE, 0);
end

-------------------------------------------------------

function Birds:InitFlock()
	self.flock = 0;
	self.currpos = {x=0,y=0,z=0};
	if (self.Properties.Options.bActivate == 1) then
		self:CreateFlock();
	end
end

-------------------------------------------------------

function Birds:OnInit()

	--self:NetPresent(0);
	--self:EnableSave(1);
	self.flock = 0;
	self:CreateFlock();
	if (self.Properties.Options.bActivate ~= 1 and self.flock ~= 0) then
		Boids.EnableFlock( self,0 );
	else
		self:RegisterForAreaEvents(1);
	end

end

-------------------------------------------------------
function Birds:OnShutDown()
end

-------------------------------------------------------
--function Birds:OnLoad(table)
--end

-------------------------------------------------------
--function Birds:OnSave(table)
--end

-------------------------------------------------------
function Birds:CreateFlock()

	local Flocking = self.Properties.Flocking;
	local Movement = self.Properties.Movement;
	local Boid = self.Properties.Boid;
	local Options = self.Properties.Options;
	local Ground = self.Properties.Ground;

	local params = self.params;

	params.count = Boid.nCount;
	params.model = Boid.object_Model;

	-- Scaling doesn't work good...disable for now
	-- params.boid_size = Boid.Size;
	-- params.boid_size_random = Boid.SizeRandom;
	params.boid_size = 1;
	params.boid_size_random = 0;
	params.min_height = Movement.HeightMin;
	params.max_height = Movement.HeightMax;
	params.min_attract_distance = Flocking.AttractDistMin;
	params.max_attract_distance = Flocking.AttractDistMax;
	params.min_speed = Movement.SpeedMin;
	params.max_speed = Movement.SpeedMax;

	if (Flocking.bEnableFlocking == 1) then
		params.factor_align = Flocking.FactorAlign;
	else
		params.factor_align = 0;
	end
	params.factor_cohesion = Flocking.FactorCohesion;
	params.factor_separation = Flocking.FactorSeparation;
	params.factor_origin = Movement.FactorOrigin;
	params.factor_keep_height = Movement.FactorHeight;
	params.factor_avoid_land = Movement.FactorAvoidLand;
	params.factor_random_accel = 0;
	params.flight_time = Movement.FlightTime;
	params.factor_take_off = Movement.FactorTakeOff;
	params.land_deceleration_height = Movement.LandDecelerationHeight;

	params.max_anim_speed = Movement.MaxAnimSpeed;
	params.follow_player = Options.bFollowPlayer;
	params.no_landing = Options.bNoLanding;
	params.start_on_ground = Options.bStartOnGround;
	params.avoid_obstacles = Options.bObstacleAvoidance;
	params.max_view_distance = Options.VisibilityDist;
	params.max_animation_distance = Options.AnimationDist;
	params.spawn_from_point = Options.bSpawnFromPoint;

	params.spawn_radius = Options.Radius;
	--params.boid_radius = Boid.boid_radius;
	params.gravity_at_death = Boid.gravity_at_death;
	params.boid_mass = Boid.Mass;
	params.invincible = Boid.bInvincible;

	params.fov_angle = Flocking.FieldOfViewAngle;

	params.ground = {};
	params.ground.factor_align = Ground.FactorAlign;
	params.ground.factor_cohesion = Ground.FactorCohesion;
	params.ground.factor_separation = Ground.FactorSeparation;
	params.ground.factor_origin = Ground.FactorOrigin;
	params.ground.walk_speed = Ground.WalkSpeed;
	params.ground.offset = Ground.HeightOffset;

	params.ground.walk_to_idle_duration = Ground.WalkToIdleDuration;
	params.ground.on_ground_idle_duration_min = Ground.OnGroundIdleDurationMin;
	params.ground.on_ground_idle_duration_max = Ground.OnGroundIdleDurationMax;
	params.ground.on_ground_walk_duration_min = Ground.OnGroundWalkDurationMin;
	params.ground.on_ground_walk_duration_max = Ground.OnGroundWalkDurationMax;

	params.Animations = self.Animations;

	if (self.flock == 0) then
		self.flock = 1;
		Boids.CreateFlock( self, Boids.FLOCK_BIRDS, params );
	end
	if (self.flock ~= 0) then
		Boids.SetFlockParams( self, params );
	end
end

-------------------------------------------------------
function Birds:OnPropertyChange()
	self:OnShutDown();
	if (self.Properties.Options.bActivate == 1) then
		self:CreateFlock();
	end
end

-------------------------------------------------------
function Birds:Event_Activate()

	if (self.Properties.Options.bActivate == 0) then
		if (self.flock==0) then
			self:CreateFlock();
		end
	end

	if (self.flock ~= 0) then
		Boids.EnableFlock( self,1 );
		self:RegisterForAreaEvents(1);
	end

	self:ActivateOutput("Activate", true);
end

-------------------------------------------------------
function Birds:Event_Deactivate()
	if (self.flock ~= 0) then
		Boids.EnableFlock( self,0 );
		self:RegisterForAreaEvents(0);
	end
	self:ActivateOutput("Deactivate", true);
end
-------------------------------------------------------
function Birds:Event_AttractTo(sender, point)
	Boids.SetAttractionPoint(self, point);
end

-------------------------------------------------------
function Birds:OnAttractPointReached()
	self:ActivateOutput("AttractEnd", true);
end

-------------------------------------------------------
function Birds:OnProceedFadeArea( player,areaId,fadeCoeff )
	if (self.flock ~= 0) then
		Boids.SetFlockPercentEnabled( self,fadeCoeff*100 );
	end
end

Birds.FlowEvents =
{
	Inputs =
	{
		Activate = { Birds.Event_Activate, "bool" },
		Deactivate = { Birds.Event_Deactivate, "bool" },
		AttractTo = { Birds.Event_AttractTo, "Vec3" },
	},
	Outputs =
	{
		Activate = "bool",
		Deactivate = "bool",
		AttractEnd = "bool",
	},
}
