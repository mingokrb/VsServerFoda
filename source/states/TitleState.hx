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
#if TOUCH_CONTROLS_ALLOWED
import flash.events.KeyboardEvent;
#end

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
	var ronaldoMode:Bool = false;
	
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
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		
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
			if (initialized) {
				startIntro();
			} else {
					if (!ronaldoMode) {
						// FIRST INIT! INITIALIZE IMPORTED PLUGINS
						ScreenshotPlugin.initialize();
					}

					new FlxTimer().start(1, function(tmr:FlxTimer)
					{
						startIntro();
					});
			}
		}
	}
	#end
	
	var logoBl:FlxSprite;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;
	
	function startIntro()
	{
		// persistentUpdate = true;
		#if TITLE_SCREEN_EASTER_EGG easterEggData(); #end

		if (!initialized && FlxG.sound.music == null) {
			if (ronaldoMode) {
				FlxG.sound.playMusic(Paths.music('freakyMenuSecret'), 0);
			} else {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
		}
		
		Conductor.bpm = musicBPM;
		
		logoBl = new FlxSprite(logoPosition.x, logoPosition.y);
		logoBl.frames = ronaldoMode ? Paths.getSparrowAtlas('logoBumpinR') : Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 48, false);
		logoBl.animation.play('bump');
		logoBl.screenCenter();
		if (ronaldoMode) logoBl.y -= 50;
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
		
		blackground = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		blackground.scale.set(FlxG.width + 4, FlxG.height + 4); // garantir que vai cobrir tudo (não cobria antes)
		//blackground.screenCenter();
		blackground.updateHitbox();
		credGroup.add(blackground);
		
		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;
		
		ngSpr = new FlxSprite(0, FlxG.height * 0.52);
		sfSpr = new FlxSprite(0, FlxG.height * 0.53);
		
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
		sfSpr.setGraphicSize(Std.int(sfSpr.width * 1.2));
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
	
	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);
	
	var musicBPM:Float = 100;
	
	var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('titleBG'));
	bg.antialiasing = ClientPrefs.data.antialiasing;
	bg.screenCenter();
	bg.updateHitbox();
	add(bg);
	
	function easterEggData()
	{
		if (FlxG.save.data.easterEgg == null) FlxG.save.data.easterEgg = ''; //Crash prevention
		var easterEgg:String = FlxG.save.data.easterEgg;
		switch(easterEgg.toUpperCase())
		{
			case 'RONALDO':
				ronaldoMode = true;
		}
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
	
	#if TOUCH_CONTROLS_ALLOWED
	var isSoftKeyPressed:Bool = false;
	var keyCode:Int = 0;
	var softKeyPressed:String = '';
	#end
	
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
		
		if (gamepad != null && !wega && !book && !FlxG.stage.window.textInputEnabled)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
			
			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if(enterTimer != null && pressedEnter && !wega && !book && !FlxG.stage.window.textInputEnabled) {
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
		#if TOUCH_CONTROLS_ALLOWED
		function onKeyDown(e:KeyboardEvent) {
			softKeyPressed = '';
			keyCode = e.keyCode;
			switch (keyCode) {
				case 16:
					softKeyPressed = '!';
			}
			isSoftKeyPressed = true;
			trace('keyCode: ' + keyCode);
			trace('softKeyPressed: ' + softKeyPressed);
		}
		#end
		
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
			
			if (pressedEnter && !wega && !book && !FlxG.stage.window.textInputEnabled)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				
				if (titleText != null)
					titleText.animation.play('press');
				
				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				
				transitioning = true;
				// FlxG.sound.music.stop();
				
				#if TOUCH_CONTROLS_ALLOWED
				FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				#end
				
				enterTimer = new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					if (mustUpdate)
					{
						MusicBeatState.switchState(new OutdatedState());
					}
					else
					{
						//FlxTransitionableState.skipNextTransIn = true;
						MusicBeatState.switchState(new MainMenuState());
					}
					
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE #if TOUCH_CONTROLS_ALLOWED || isSoftKeyPressed #end)
			{
				#if TOUCH_CONTROLS_ALLOWED
				var flxKey:FlxKey = cast keyCode;
				var keyPressed:FlxKey = isSoftKeyPressed ? flxKey : FlxG.keys.firstJustPressed();
				isSoftKeyPressed = false;
				#else
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				#end
				var keyName:String = Std.string(keyPressed);
				#if TOUCH_CONTROLS_ALLOWED
				if (softKeyPressed != '') keyName = softKeyPressed;
				#end
				// Culpe o HaxeFlixel por isso
				switch (keyName) {
					case 'ONE':
						if (FlxG.keys.pressed.SHIFT)
							keyName = '!';
						else 
							keyName = '1';
					case 'TWO':
						keyName = '2';
					case 'THREE':
						keyName = '3';
					case 'FOUR':
						keyName = '4';
					case 'FIVE':
						keyName = '5';
					case 'SIX':
						keyName = '6';
					case 'SEVEN':
						keyName = '7';
					case 'EIGHT':
						keyName = '8';
					case 'NINE':
						keyName = '9';
					case 'ZERO':
						keyName = '0';
				}

				if (allowedKeys.contains(keyName))
				{
					easterEggKeysBuffer += keyName;
					if (easterEggKeysBuffer.length >= 32)
						easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
					// debug //
					trace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);
					trace('Acabou de apertar ' + keyName);
					///////////
					
					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase(); // just for being sure you're doing it right
						if (easterEggKeysBuffer.contains(word))
						{
							#if TOUCH_CONTROLS_ALLOWED // fechar teclado virtual ao digitar segredo
							FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
							FlxG.stage.window.textInputEnabled = false;
							#end
							// trace('YOOO! ' + word);
							// if (FlxG.save.data.easterEgg == word)
							// 	FlxG.save.data.easterEgg = '';
							// else
							// 	FlxG.save.data.easterEgg = word;
							// FlxG.save.flush();
							switch (word) {
								case '53488':
									FlxG.sound.music.stop();
									var uncannySpr:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('uncanny'));
									uncannySpr.antialiasing = true;
									uncannySpr.screenCenter();
									uncannySpr.updateHitbox();
									add(uncannySpr);
									book = true;
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
								case 'RONALDO':
									if (FlxG.save.data.easterEgg == word) {
										FlxG.save.data.easterEgg = '';
									} else {
										FlxG.save.data.easterEgg = word;
									}
									FlxG.save.flush();

									transitioning = true;
									FlxG.sound.music.fadeOut();
									FlxG.sound.play(Paths.sound('secretR'));

									var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
									black.scale.set(FlxG.width, FlxG.height);
									black.updateHitbox();
									black.alpha = 0;
									add(black);

									var white:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1, ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF);
									white.scale.set(FlxG.width, FlxG.height);
									white.updateHitbox();
									white.alpha = 0;
									add(white);
									new FlxTimer().start(1.2, function(tmr:FlxTimer) { // Flashbang
										FlxTween.tween(white, {alpha: 1}, 0.1, {
										onComplete: function(twn:FlxTween) {
											black.alpha = 1;
											new FlxTimer().start(3.0, function(tmr:FlxTimer) {
												FlxTween.tween(white, {alpha: 0}, 2.0, {
													onComplete: function(twn:FlxTween) {
														FlxTransitionableState.skipNextTransIn = true;
														FlxTransitionableState.skipNextTransOut = true;
														MusicBeatState.switchState(new TitleState());
														if (FlxG.save.data.easterEgg == word) {
															initialized = false;
														}
														closedState = false;
													}
												});
											});
										}
										});
									});
								case 'TADB':
									if (FlxG.random.bool(50)) {
										FlxG.sound.play(Paths.sound('huh'));
									} else {
										FlxG.sound.play(Paths.sound('violin'));
									}
							}
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}
		
		if (initialized && pressedEnter && !skippedIntro)
			skipIntro();
		
		#if desktop
		if (!wega && !book)
			if (controls.BACK) openfl.Lib.application.window.close();
		#end

		// abrir teclado virtual ao deslizar pra cima (salve pro PsychUIInputText.hx)
		#if TOUCH_CONTROLS_ALLOWED
		if (skippedIntro && !transitioning && !wega && !book) {
			if (SwipeUtil.swipeAny && !FlxG.stage.window.textInputEnabled) {
				if (SwipeUtil.swipeDown) {
					FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
					FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
					FlxG.stage.window.textInputEnabled = true;
				}
			}
		}
		#end
		
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
		#if TITLE_SCREEN_EASTER_EGG easterEggData(); #end
		if (!closedState)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					FlxG.sound.music.stop();
					if (ronaldoMode)
						FlxG.sound.playMusic(Paths.music('freakyMenuSecret'), 0);
					else
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					// #if VIDEOS_ALLOWED
					// 	FlxG.sound.music.onComplete = moveToAttract;
					// #end
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
					addMoreText('NewGrounds', -40);
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
					addMoreText('Vs', 20);
				case 15:
					addMoreText('Server', 52);
				case 16:
					addMoreText(ronaldoMode ? 'AAAAAAAAAAAAAAAAAAAAAAAAAAIIIIIIII' : 'Foda', 84); // credTextShit.text += '\nFoda';
				
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
			// #if VIDEOS_ALLOWED
			// 	FlxG.sound.music.onComplete = moveToAttract;
			// #end
			// #if TITLE_SCREEN_EASTER_EGG
			// 	var easteregg:String = FlxG.save.data.easterEgg;
			// 	if (easteregg == null)
			// 		easteregg = '';
			// 	easteregg = easteregg.toUpperCase();
				
			// 	//var sound:FlxSound = null;
			// 	switch (easteregg)
			// 	{
			// 		case 'RONALDO':
			// 			if (FlxG.sound.music.volume == 0) {
			// 				FlxG.sound.playMusic(Paths.music('freakyMenuSecret'), 0);
			// 				FlxG.sound.music.fadeIn(4, 0, 0.7);
			// 			}
					
			// 		default: // Go back to normal ugly ass boring GF -- Não tem GF aqui não doidão kkkkkkk
			// 			if (FlxG.sound.music.volume == 0) {
			// 				trace('RODOU AQUI - easteregg Switch');
			// 				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			// 				FlxG.sound.music.fadeIn(4, 0, 0.7);
			// 			}
			// 	}
			// #end // Default! Edit this one!!	*/
			remove(ngSpr);
			remove(sfSpr);
			remove(credGroup);
			FlxG.camera.flash(FlxColor.WHITE, 4);
			skippedIntro = true;
		}
	}
	
	function restartGame():Void // pro ronaldoMode não quebrar
	{
		//FlxG.cameras.remove();
		initialized = false;
    ScreenshotPlugin.instance.destroy();
    ScreenshotPlugin.instance = null;
		closedState = false;
		if (Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
		if (Main.memoryCounter != null)
			Main.memoryCounter.visible = ClientPrefs.data.showFPS;
		FlxG.sound.pause();
		FlxTween.globalManager.clear();
		FlxG.resetGame();
	}
	
	/**
	 * After sitting on the title screen for a while, transition to the attract screen. ----- Dá pra fazer algo com isso com certeza
	 */
	// function moveToAttract():Void
	// {	#if VIDEOS_ALLOWED
	// 	if(!Std.isOfType(FlxG.state,TitleState)) return;
	// 	FlxG.switchState(() -> new AttractState());
	// 	#end
	// }
}
