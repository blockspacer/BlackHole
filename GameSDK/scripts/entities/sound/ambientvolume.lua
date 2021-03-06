AmbientVolume = {
	type = "AmbientVolume",
  
  Editor={
		Model="Editor/Objects/Sound.cgf",
		Icon="AmbientVolume.bmp",
	},
  
	Properties = {
		soundName = "",
		--iVolume=255,
		OuterRadius = 10,
		bEnabled = 1,
		bIgnoreCulling=0,
		bIgnoreObstruction=0,
		bSensitiveToBattle = 0,
		bLogBattleValue = 0,
		bSerializePlayState = 1,
	},
  
  bStarted = 0,
	bEnabled = 1,
  bIsNear = 0,
  bInside = 0,
	fFade = 0,
}


function AmbientVolume:OnSpawn()
	self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0);
	
	--System.Log("AV: OSpawn!");
	--if (self.bGameStarted == 0) then
	--end;
	
	if (System.IsEditor()) then
		Sound.Precache(self.Properties.soundName, SOUND_PRECACHE_LOAD_SOUND);
	end;
	
end

function AmbientVolume:OnSave(save)
	--WriteToStream(stm,self.Properties);
	save.bStarted = self.bStarted;
	save.bEnabled = self.Properties.bEnabled;
	save.bIgnoreCulling = self.Properties.bIgnoreCulling;
	save.bIgnoreObstruction = self.Properties.bIgnoreObstruction;
	save.bSensitiveToBattle = self.Properties.bSensitiveToBattle;
	save.bLogBattleValue = self.Properties.bLogBattleValue;
	
	--System.Log("AV: ONSAVE!"..tostring(self.soundid));
	if (self.soundid ~= nil) then
	   save.fLastVolume = Sound.GetSoundVolume(self.soundid);
	   --System.Log("AV: Save LastVolume!"..tostring(save.fLastVolume));
	end;
	
end

function AmbientVolume:OnLoad(load)
	--self.Properties=ReadFromStream(stm);
	--self:OnReset();
	
	
	self.bStarted = load.bStarted;
	self.Properties.bEnabled = load.bEnabled;
	self.Properties.bIgnoreCulling = load.bIgnoreCulling;
	self.Properties.bIgnoreObstruction = load.bIgnoreObstruction;
	self.Properties.bSensitiveToBattle = load.bSensitiveToBattle
	self.Properties.bLogBattleValue = load.bLogBattleValue

	self:OnReset();

	
	if ((self.Properties.bSerializePlayState==1) and (self.bStarted==1) and (self.Properties.bOnce~=1)) then
    self:Play();
	end	
	
	--System.Log("AV: LastVolume!");
	if (self.soundid ~= nil) then
			--System.Log("AV: Load LastVolume!"..tostring(load.fLastVolume));
	   Sound.SetSoundVolume(self.soundid, load.fLastVolume);
	end;
	
	--System.Log("AV: ONLOAD!");

		
end

--function AmbientVolume:OnStartGame()
	--System.Log("AV: OnStartGame!");
	--self.bGameStarted = 1;
--end

----------------------------------------------------------------------------------------
function AmbientVolume:OnPropertyChange()
  --System.Log("AV: OnPropertyChange");
  self:OnReset();
end

----------------------------------------------------------------------------------------
function AmbientVolume:OnReset()
  self:Stop();
	self:SetSoundEffectRadius(self.Properties.OuterRadius);
	self.bEnabled = self.Properties.bEnabled;
  self.soundName = self.Properties.soundName;
    
  if(self.Properties.bEnabled == 1 and (self.bIsNear == 1 or self.bInside == 1)) then
    self:Play();
  end
  
  if (self.soundid ~= nil) then
    Sound.SetSoundVolume(self.soundid, self.fFade);
	end
end

----------------------------------------------------------------------------------------
function AmbientVolume:UpdateBattleNoise()

    --System.Log("Updating Battle Noise...");
    
		if (self.Properties.bSensitiveToBattle == 1 and self.soundid) then
	  	local fBattle = Game.QueryBattleStatus();
	  	Sound.SetParameterValue(self.soundid, "battle", fBattle);
	  	
	  	if (self.Properties.bLogBattleValue == 1) then
	  		System.Log("AV: Current Battle Value :".. tostring(fBattle));
	  	end;
	  	
	  	self:SetTimer(1, 300); -- timer for updating battle parameter
	  	--System.Log("Updating Battle Noise :".. tostring(fBattle));
	  else
	  	self:KillTimer(1);
	  end;
end

----------------------------------------------------------------------------------------
function AmbientVolume:CliSrv_OnInit()
  self.bStarted = 0;
  self.bEnabled = self.Properties.bEnabled;
  self.bIsNear = 0;
	self.bInside = 0;
  self.fFade = 0;
  self.soundName = "";
  self.soundid = nil;
  --self.bSensitive = 0;
	self:SetFlags(ENTITY_FLAG_VOLUME_SOUND,0);
end

----------------------------------------------------------------------------------------
AmbientVolume["Server"] = {
	OnInit= function(self)
    self:CliSrv_OnInit();
	end,
  
	OnShutDown= function(self)
	end,
}

----------------------------------------------------------------------------------------
AmbientVolume["Client"] = {
  OnInit = function(self)
    --System.Log("OnInit");
    self:CliSrv_OnInit();
		self:SetSoundEffectRadius(self.Properties.OuterRadius);
		self:RegisterForAreaEvents(1);
  end,
    
	OnShutDown = function(self)
    self:RegisterForAreaEvents(0);
	end,
  
	OnAudioListenerEnterArea = function(self, player, nAreaID, fFade)
    self.bIsNear = 0;
	  self.bInside = 1;
	  
    if (self.soundid == nil) then
	    self:Play();
	  end

	  if (fFade == -1) then
	     fFade = 1;
	  end
	  
	  Sound.SetSoundVolume(self.soundid, fFade);
	  
	  if (self.fFade ~= fFade) then
	  	--self.fFade = 1;
	  	
	  	if (fFade < 0) then
	  		self.fFade = 0;
	  	else
	  		self.fFade = fFade;
	  	end;
	  	
	  	--System.Log("Fade now: "..tostring(self.fFade));
	  end;
	  
	end,
	OnAudioListenerProceedFadeArea = function(self, player, nAreaID, fFade)
		--System.Log("Sound ID now: "..tostring(self.soundid));
		
	  if (self.soundid == nil) then
	    self:Play();
	  end;
	  
	  --System.Log("AV: selfFade: "..tostring(self.fFade));
	  --System.Log("AV: new Fade: "..tostring(fFade));
	  
	  Sound.SetSoundVolume(self.soundid, fFade);
	  
	  if (self.fFade ~= fFade) then
	  	--self.fFade = 1;
	  	
	  	if (fFade < 0) then
	  		self.fFade = 0;
	  	else
	  		self.fFade = fFade;
	  	end;
	  	
	  	--System.Log("Fade now: "..tostring(self.fFade));
	  end;
	  
	end,
	OnAudioListenerEnterNearArea = function(self, player, nAreaID, fFade)
    self.bIsNear = 1;
	  self.bInside = 0;
    
	  if (self.soundid == nil) then
	    self:Play();
	  end
	end,
	
	OnAudioListenerMoveNearArea = function(self, player, nAreaID, fFade)
    self.bIsNear = 1;
	  self.bInside = 0;
    
	  if (self.soundid == nil) then
	    self:Play();
	  end
	end,
	
	OnAudioListenerLeaveNearArea = function(self, player, nAreaID, fFade)
    self.bIsNear = 0;
    
	  if (self.bInside ~= 1) then
	    self:Stop();
	  end
	end,
	
	OnAudioListenerLeaveArea = function(self, player, nAreaID, fFade)
	  self.bIsNear = 1;
	  self.bInside = 0;
	end,
	
	OnTimer = function(self, timerid, msec)
		
		--System.Log("------------ AB OnTimer :"..timerid);
	
	 	if (timerid == 1) then
	 		--System.Log("------------ AB OnTimer :"..timerid);
	   	self:UpdateBattleNoise();
	   	
	 	end;
	 	
		--self:RemoveDecals();
	end,
	
	OnUnBindThis = function(self)
		--System.LogToConsole("OnUnBindThis-Client");
		self:Stop();
		self.bInside = 0;
	end,	
}

----------------------------------------------------------------------------------------
function AmbientVolume:Play()

  --System.Log( "...Try to Play Sound AV 1" );
  
	if (self.Properties.bEnabled == 0 ) then 
		do return end;
	end

	if (self.soundid ~= nil) then
		self:Stop();
	end
	
	local sndFlags = SOUND_DEFAULT_3D;
	
	if (self.Properties.bIgnoreCulling == 1) then
	  sndFlags = band(sndFlags, bnot(SOUND_CULLING))
	end;  

	if (self.Properties.bIgnoreObstruction == 1) then
	  sndFlags = band(sndFlags, bnot(SOUND_OBSTRUCTION))
	end;  
	
	sndFlags = bor(sndFlags, SOUND_START_PAUSED)
	
	--System.Log( "...Try to Play Sound AV 2a");
  -- Since these type of events mustn't provide their own distance parameter we need to forward this script's outer radius for the sound event's max distance. (sound obstruction wouldn't work properly)
	self.soundid = self:PlaySoundEventEx(self.Properties.soundName, sndFlags, 0, 0.0, g_Vectors.v000, 0.1, self.Properties.OuterRadius, SOUND_SEMANTIC_AMBIENCE);
	
	-- helps to fade in the ambient without pops.
	Sound.SetFadeTime(self.soundid, 1.0, 300);
	Sound.SetSoundVolume(self.soundid, 0.0);
	--Sound.SetSoundVolume(self.soundid, 1.0*self.fFade);
	--System.Log( "AV Start to Play "..tostring(self.fFade));
	
	self:UpdateBattleNoise();
	Sound.SetSoundPaused(self.soundid, 0);
	
	self.soundName = self.Properties.soundName;
	--self.volume = self.Properties.iVolume;

	--System.Log( "----- AV Play Sound" );
	if (self.soundid ~= nil) then
  	self.bStarted = 1;
	end;
	
	
end

----------------------------------------------------------------------------------------
function AmbientVolume:Stop()

	--System.Log( "Stop Sound AV 0" );
	
	if (self.soundid ~= nil) then
		self:StopSound(self.soundid); -- stopping through entity proxy
		
		--System.Log( "Stop Sound AV 1" );
		
		self.soundid = nil;
	end
	self.bStarted = 0;
	self:KillTimer(1);

end


------------------------------------------------------------------------------------------------------
-- Event Handlers
------------------------------------------------------------------------------------------------------

function AmbientVolume:Event_SoundName( sender, sSoundName )
  self.Properties.soundName = sSoundName;
  --BroadcastEvent( self,"SoundName" );
  self:OnReset();
end

function AmbientVolume:Event_Deactivate(sender)
  --System.Log("AV: FG event - Deactivate");
  self.Properties.bEnabled = 0;
  self:OnPropertyChange();
end

----------------------------------------------------------------------------------------------------
function AmbientVolume:Event_Activate(sender)
	--System.Log("AV: FG event - Activate");
	self.Properties.bEnabled = 1;
	self:OnPropertyChange();
end

function AmbientVolume:Event_Radius( sender, fRadius )
  --System.Log( "Ambient Volume :Enable radius");
	
	--self:Stop();
	--BroadcastEvent( self,"Radius" );
end

--function AmbientVolume:Event_Volume( fVolume )
	
	--self.Properties.iVolume = fVolume;
	--BroadcastEvent( self,"Volume" );
--end

AmbientVolume.FlowEvents =
{
	Inputs =
	{
	  sound_SoundName = { AmbientVolume.Event_SoundName, "string" },
		--Enable = { AmbientVolume.Event_Enable, "bool" },
		Deactivate = { AmbientVolume.Event_Deactivate, "bool" },
		Activate   = { AmbientVolume.Event_Activate, "bool" },
		Radius = { AmbientVolume.Event_Radius, "float" },
		--Volume = { AmbientVolume.Event_Volume, "float" },
	},
	Outputs =
	{
	},
}

