package states;

import states.editors.ChartingState;
import backend.WeekData;
import backend.Song;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxDirectionFlags;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import haxe.Json;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import shaders.ColorSwap;

import states.OutdatedState;
import mikolka.vslice.components.ScreenshotPlugin;
#if VIDEOS_ALLOWED
import mikolka.vslice.AttractState;
#end
#if android
import mobile.backend.PsychJNI
#end

typedef TitleData =
{
	var titlex:Float;
	var titley:Float;
	var startx:Float;
	var starty:Float;
	var backgroundSprite:String;
	var bpm:Float;
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	
	public static var initialized:Bool = false;
	
	var enterTimer:FlxTimer;
	
	var credGroup:FlxGroup = new FlxGroup();
	var textGroup:FlxGroup = new FlxGroup();
	var blackground:FlxSprite; // gostou do trocadilho kkkkkkkkkk valeu!
	var credTextShit:Alphabet;
	var ngSpr:FlxSprite;
	var sfSpr:FlxSprite;
	
	var wega:Bool = false;
	var book:Bool = false;
	
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];
	
	var curWacky:Array<String> = [];
	
	var wackyImage:FlxSprite;
	
	#if TITLE_SCREEN_EASTER_EGG
	final easterEggKeys:Array<String> = [
		'CORE', 'BAAAAAAAAAAH!!!!!', 'RONALDO', '53488', 'TADB'
	];
	final allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!';
	var easterEggKeysBuffer:String = '';
	#end
	
	var mustUpdate:Bool = false;
	
	public static var updateVersion:String = '';
	
	override public function create():Void
	{
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();
		
		if(!initialized)
		{
			ClientPrefs.loadPrefs();
			Language.reloadPhrases();
		}
		
		curWacky = FlxG.random.getObject(getIntroTextShit());
		
		#if CHECK_FOR_UPDATES
		if (ClientPrefs.data.checkForUpdates && !closedState)
		{
			trace('buscando atualizações');
			var http = new haxe.Http("https://raw.githubusercontent.com/mingokrb/VsServerFoda/master/gitVersion.txt");
			
			http.onData = function(data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.pSliceVersion.trim();
				trace('versão online: ' + updateVersion + ', sua versão: ' + curVersion);
				if (updateVersion != curVersion)
				{
					trace('versões não combinam!');
					mustUpdate = true;
				}
			}
			
			http.onError = function(error)
			{
				trace('erro: $error');
			}
			
			http.request();
		}
		#end
		
		if(!initialized)
		{
			if (FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
				// trace('CONFIGURAÇÃO DE TELA CHEIA CARREGADA!!');
			}
			persistentUpdate = true;
			persistentDraw = true;
			#if TOUCH_CONTROLS_ALLOWED
			MobileData.init();
			#end
		}
		
		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}
		
		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if (FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			controls.isInSubstate = false;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
		{
			if (initialized)
				startIntro();
			else
			{
				//* FIRST INIT! iNITIALISE IMPORTED PLUGINS
				ScreenshotPlugin.initialize();
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					startIntro();
				});
			}
		}
		#end
	}
	
	var logoBl:FlxSprite;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;
	
	function startIntro()
	{
		persistentUpdate = true;
		if (!initialized && FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		
		loadJsonData();
		#if TITLE_SCREEN_EASTER_EGG easterEggData(); #end
		Conductor.bpm = musicBPM;
		
		logoBl = new FlxSprite(logoPosition.x, logoPosition.y);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.screenCenter();
		logoBl.updateHitbox();
		
		// reutilizei mesmo... vai fazer o quê... hein...
		FlxTween.tween(logoBl, {y: logoBl.y + 10}, 1, {ease: FlxEase.quadInOut, type: PINGPONG});
		FlxTween.tween(logoBl, {angle: logoBl.angle - 0.5}, 0.05, {ease: FlxEase.linear}); // tiltada pra esquerda pra equilibrar a balançada contínua (lá ele mil vezes)
		FlxTween.tween(logoBl, {angle: logoBl.angle + 1}, 2.2, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});
		
		if(ClientPrefs.data.shaders)
		{
			swagShader = new ColorSwap();
			logoBl.shader = swagShader.shader;
		}
		
		var animFrames:Array<FlxFrame> = [];
		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (newTitle = animFrames.length > 0)
		{
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.animation.play('idle');
		titleText.updateHitbox();
		
		if (swagShader != null)
		{
			logoBl.shader = swagShader.shader;
			titleText.shader = swagShader.shader;
		}
		
		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.screenCenter();
		
		blackground = new FlxSprite().makeGraphic(0, 0, FlxColor.BLACK);
		blackground.scale.set(FlxG.width + 4, FlxG.height + 4); // garantir que vai cobrir tudo (não cobria antes)
		//blackground.screenCenter();
		blackground.updateHitbox();
		credGroup.add(blackground);
		
		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;
		
		ngSpr = new FlxSprite(0, FlxG.height * 0.52);
		sfSpr = new FlxSprite(0, FlxG.height * 0.52);
		
		#if desktop
		if (FlxG.random.bool(1))
		{
			ngSpr.loadGraphic(Paths.image('newgrounds_logo_classic'));
		}
		else if (FlxG.random.bool(30))
		{
			ngSpr.loadGraphic(Paths.image('newgrounds_logo_animated'), true, 600);
			ngSpr.animation.add('idle', [0, 1], 4);
			ngSpr.animation.play('idle');
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.55));
			ngSpr.y += 25;
		}
		else
		{
			ngSpr.loadGraphic(Paths.image('newgrounds_logo'));
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		}
		#else
		ngSpr.loadGraphic(Paths.image('newgrounds_logo'));
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		#end
		
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.data.antialiasing;
		ngSpr.visible = false;
		
		if (FlxG.random.bool(1)) {
			sfSpr.loadGraphic(Paths.image('serverfodatadb_logo'));
		} else if (FlxG.random.bool(20)) {
			sfSpr.loadGraphic(Paths.image('serverfodatuah_logo'));
		} else {
			sfSpr.loadGraphic(Paths.image('serverfodateam_logo'));
		}
		//sfSpr.setGraphicSize(Std.int(sfSpr.width * 0.8));
		sfSpr.updateHitbox();
		sfSpr.screenCenter(X);
		sfSpr.antialiasing = false;
		sfSpr.visible = false;
		
		add(logoBl); //FNF Logo
		add(titleText); //"Press Enter to Begin" text
		add(credGroup);
		add(ngSpr);
		add(sfSpr);
		
		if (initialized)
			skipIntro();
		else
			initialized = true;
		
		// credGroup.add(credTextShit);
	}
	
	// JSON data
	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);
	
	var musicBPM:Float = 102;
	
	function loadJsonData()
	{
		if(Paths.fileExists('data/title.json', TEXT))
		{
			var titleRaw:String = Paths.getTextFromFile('data/title.json');
			if(titleRaw != null && titleRaw.length > 0)
			{
				try
				{
					var titleJSON:TitleData = tjson.TJSON.parse(titleRaw);
					logoPosition.set(titleJSON.titlex, titleJSON.titley);
					enterPosition.set(titleJSON.startx, titleJSON.starty);
					musicBPM = titleJSON.bpm;
					
					var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('titleBG'));
					bg.antialiasing = ClientPrefs.data.antialiasing;
					add(bg);
				}
				catch(e:haxe.Exception)
				{
					trace('[WARN] Title JSON possivelmente quebrado, ignorando problema...\n${e.details()}');
				}
			}
			else trace('[WARN] Nenhum Title JSON detectado, usando valores padrão.');
		}
		//else trace('[WARN] Nenhum Title JSON detectado, usando valores padrão.');
	}
	
	function easterEggData()
	{
		// if (FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = ''; //Crash prevention
		// var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		// switch(easterEgg.toUpperCase())
		// {

		// }
	}
	
	function getIntroTextShit():Array<Array<String>>
	{
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt');
		#else
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		var swagGoodArray:Array<Array<String>> = [];
		
		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}
		
		return swagGoodArray;
	}
	
	var transitioning:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;
	
	override function update(elapsed:Float)
	{
		#if debug
		if (controls.FAVORITE)
			moveToAttract();
		#end
		//if (skippedIntro)
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);
		
		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT || (TouchUtil.justReleased && !SwipeUtil.swipeAny);
		
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		
		if (gamepad != null && !wega && !book)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
			
			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if(enterTimer != null && pressedEnter && !wega && !book){
			enterTimer.cancel();
			enterTimer.onComplete(enterTimer);
			enterTimer = null;
		}
		
		if (newTitle)
		{
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2)
				titleTimer -= 2;
		}
		
		// EASTER EGG
		
		if (initialized && !transitioning && skippedIntro && !wega && !book)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if (pressedEnter && !wega && !book)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				
				if (titleText != null)
					titleText.animation.play('press');
				
				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				
				transitioning = true;
				// FlxG.sound.music.stop();
				
				enterTimer = new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					if (mustUpdate)
					{
						MusicBeatState.switchState(new OutdatedState());
					}
					else
					{
						FlxTransitionableState.skipNextTransIn = true;
						MusicBeatState.switchState(new MainMenuState());
					}
					
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if (allowedKeys.contains(keyName))
				{
					easterEggKeysBuffer += keyName;
					if (easterEggKeysBuffer.length >= 32)
						easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
					// trace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);
					
					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase(); // just for being sure you're doing it right
						if (easterEggKeysBuffer.contains(word))
						{
							// trace('YOOO! ' + word);
							// if (FlxG.save.data.psychDevsEasterEgg == word)
							// 	FlxG.save.data.psychDevsEasterEgg = '';
							// else
							// 	FlxG.save.data.psychDevsEasterEgg = word;
							// FlxG.save.flush();
							switch (word) {
								case 'CORE':
									if (FlxG.random.bool(25)) {
										FlxG.sound.play(Paths.sound('fart'));
									} else if (FlxG.random.bool(25)) {
										FlxG.sound.play(Paths.sound('sadhorn'));
									} else if (FlxG.random.bool(25)) {
										FlxG.sound.play(Paths.sound('fail'));
									} else {
										FlxG.sound.play(Paths.sound('stinky'));
									}
								case 'BAAAAAAAAAAH!!!!!':
									FlxG.sound.play(Paths.sound('wegascare'));
									FlxG.sound.music.fadeOut(1, 0);
									var wegaSpr:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('wega'));
									wegaSpr.scale.set(FlxG.width, FlxG.height);
									wegaSpr.updateHitbox();
									//wegaSpr.alpha = 0;
									add(wegaSpr);
									var wegaTimer = new FlxTimer().start(1, function(tmr:FlxTimer)
									{
										// de FunkinLua.hx
										var wegasong = Highscore.formatSong('wega', 3);
										Song.loadFromJson(wegasong, 'wega');
										PlayState.storyDifficulty = 3;
										FlxG.state.persistentUpdate = false;
										LoadingState.loadAndSwitchState(new PlayState());
									});									
									wega = true;
								case 'RONALDO':
									if (FlxG.random.bool(33)) {
										FlxG.sound.play(Paths.sound('ronaldo'));
									} else if (FlxG.random.bool(33)) {
										FlxG.sound.play(Paths.sound('tatuador'));
									} else {
										FlxG.sound.play(Paths.sound('cuica'));
									}
								case '53488':
									FlxG.sound.music.stop();
									var uncannySpr:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('uncanny'));
									uncannySpr.scale.set(FlxG.width, FlxG.height);
									uncannySpr.updateHitbox();
									add(uncannySpr);
									book = true;
								case 'TADB':
									if (FlxG.random.bool(50)) {
										FlxG.sound.play(Paths.sound('huh'));
									} else {
										FlxG.sound.play(Paths.sound('violin'));
									}
							}
							easterEggKeysBuffer = '';
						}
					}
				}
			}
			#end
		}
		
		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}
		
		if (!wega && !book)
		{
			/*if (swagShader != null)
			{
				if (cheatActive && TouchUtil.pressed || controls.UI_LEFT)
					swagShader.hue -= elapsed * 0.1;
				if (controls.UI_RIGHT)
					swagShader.hue += elapsed * 0.1;
			}
			#if FLX_PITCH
			if (controls.UI_UP) FlxG.sound.music.pitch += 0.5 * elapsed;
			if (controls.UI_DOWN) FlxG.sound.music.pitch -= 0.5 * elapsed;
			#end*/
			#if desktop
			if (controls.BACK) openfl.Lib.application.window.close();
			#end
		}
		
		super.update(elapsed);
	}
	
	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			if (ClientPrefs.data.vibrating)
				lime.ui.Haptic.vibrate(100, 100);
			
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			
			if (credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}
	
	function addMoreText(text:String, ?offset:Float = 0)
	{
		if (textGroup != null && credGroup != null)
		{
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}
	
	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}
	
	private var sickBeats:Int = 0; // Basically curBeat but won't be skipped if you hold the tab or resize the screen
	
	public static var closedState:Bool = false;
	
	override function beatHit()
	{
		super.beatHit();
		
		if (logoBl != null)
			logoBl.animation.play('bump', true);
		
		//if (cheatActive && this.curBeat % 2 == 0 && swagShader != null)
		//	swagShader.hue += 0.125;
		
		if (!closedState)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					// FlxG.sound.music.stop();
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					#if VIDEOS_ALLOWED
						FlxG.sound.music.onComplete = moveToAttract;
					#end
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					addMoreText('Server Foda Team', -40);
				case 3:
					addMoreText('mingokrb', -40);
				case 4:
					addMoreText('apresentam', -40);
					sfSpr.visible = true;
				case 5:
					deleteCoolText();
					sfSpr.visible = false;
				case 6:
					addMoreText('Não associado', -40);
				case 7:
					addMoreText('com', -40);
				case 8:
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				case 10:
					if (curWacky[1] != " ")
						addMoreText(curWacky[0]);
					else
						addMoreText(curWacky[0], 40);
				case 11:
					if (curWacky[1] != " ")
						addMoreText(curWacky[1]);
				case 12:
					if (curWacky[1] != " ")
						addMoreText(curWacky[2]);
					else
						addMoreText(curWacky[2], 40);
				case 13:
					deleteCoolText();
				case 14:
					addMoreText('vs', 20);
				case 15:
					addMoreText('Server', 52);
				case 16:
					addMoreText('Foda', 84); // credTextShit.text += '\nFoda';
				
				case 17:
					skipIntro();
			}
		}
	}
	
	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			#if VIDEOS_ALLOWED
				FlxG.sound.music.onComplete = moveToAttract;
			#end
			/*	#if TITLE_SCREEN_EASTER_EGG
			if (wega) // Ignore deez
			{
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null)
					easteregg = '';
				easteregg = easteregg.toUpperCase();
				
				//var sound:FlxSound = null;
				switch (easteregg)
				{
					case 'BAAAAAAAAAAH!!!!!':
						new FlxTimer().start(2, function(tmr:FlxTimer)
						{
							MusicBeatState.switchState(new TitleState());
						});
					
					default: // Go back to normal ugly ass boring GF
						remove(ngSpr);
						remove(sfSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 2);
						skippedIntro = true;
						
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						return;
				}
			}
			else
			#end // Default! Edit this one!!	*/
			{
				remove(ngSpr);
				remove(sfSpr);
				remove(credGroup);
				FlxG.camera.flash(FlxColor.WHITE, 4);
				
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null)
					easteregg = '';
				easteregg = easteregg.toUpperCase();
			}
			skippedIntro = true;
		}
	}
	
	// abrir teclado virtual ao deslizar pra cima
	/* #if android
	if (SwipeUtil.swipeAny)
	{
		if (SwipeUtil.swipeUp)
			//PsychJNI.isScreenKeyboardShown();
	}
	#end /*
	
	/**
	 * After sitting on the title screen for a while, transition to the attract screen.
	 */
	function moveToAttract():Void
	{	#if VIDEOS_ALLOWED
		if(!Std.isOfType(FlxG.state,TitleState)) return;
		FlxG.switchState(() -> new AttractState());
		#end
	}
}
