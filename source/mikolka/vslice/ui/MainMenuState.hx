package mikolka.vslice.ui;

import mikolka.compatibility.ui.MainMenuHooks;
import mikolka.compatibility.VsliceOptions;
#if !LEGACY_PSYCH
import states.TitleState;
import states.CommandsState;
import states.AchievementsMenuState;
import states.CreditsState;
import states.editors.MasterEditorMenu;
#else
import editors.MasterEditorMenu;
#end
import mikolka.compatibility.ModsHelper;
import mikolka.vslice.freeplay.FreeplayState;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4'; // This is also used for Discord RPC
	public static var vsfVersion:String = '0.1'; // mudar com o tempo!!!!!!!!!!!!!!
	public static var pSliceVersion:String = '3.1.1'; 
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var bottom:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'commands', // favela dos bots
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits'
	];

	var camFollow:FlxObject;
	public function new(isDisplayingRank:Bool = false) {

		//TODO
		super();
	}
	override function create()
	{
		Paths.clearUnusedMemory();
		ModsHelper.clearStoredWithoutStickers();
		
		ModsHelper.resetActiveMods();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Nos Menus", null);
		#end


		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('mainmenu/menuBG'));
		bg.antialiasing = false;
		bg.scrollFactor.set();
		//bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		//add(camFollow);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(60, (i * 140) + offset);
			menuItem.antialiasing = false; //VsliceOptions.ANTIALIASING
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/buttons/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 0);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " chosen", 0);
			menuItem.animation.addByPrefix('clicked', optionShit[i] + " click", 0);
			menuItem.animation.play('idle');
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.updateHitbox();
		}
		
		bottom = new FlxTypedGroup<FlxSprite>();
		add(bottom);
		
		var profileBottomBG:FlxSprite = new FlxSprite(100, FlxG.height - 24).loadGraphic(Paths.image('mainmenu/profileBottomBG'));
		profileBottomBG.antialiasing = false;
		bottom.add(profileBottomBG);
		
		var optionsButton:FlxSprite = new FlxSprite(280, FlxG.height - 24);
		optionsButton.antialiasing = false;
		optionsButton.frames = Paths.getSparrowAtlas('mainmenu/buttons/menu_options');
		optionsButton.animation.addByPrefix('idle', "options basic", 0);
		optionsButton.animation.addByPrefix('clicked', "options click", 0);
		optionsButton.animation.play('idle');
		menuItems.add(optionsButton);
		
		var psychVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, "P-Slice Engine v" + pSliceVersion, 12);
		var vsfVer:FlxText = new FlxText(0, 16, FlxG.width, "v" + vsfVersion, 12);
		
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		vsfVer.setFormat(Paths.font("ggsans/bold.ttf"), 16, 0xFF818491, CENTER); //, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		vsfVer.scrollFactor.set();
		vsfVer.screenCenter(X);
		add(vsfVer);
		
		psychVer.scrollFactor.set();
		//add(psychVer);
		//var vsfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' ", 12);
	
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) MainMenuHooks.unlockFriday();
			

		#if MODS_ALLOWED
		MainMenuHooks.reloadAchievements();
		#end
		#end

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('NONE', 'B_E'); // tirar o '_E' na versão final!!!!!!!!!!
		#end

		super.create();

		FlxG.camera.follow(camFollow, null, 0.06);
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			//if (FreeplayState.vocals != null)
				//FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://needlejuicerecords.com/pages/friday-night-funkin');
				}
				else
				{
					selectedSomethin = true;
					
					menuItems.members[curSelected].animation.play('clicked');
					FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						switch (optionShit[curSelected])
						{
							case 'story_mode':
								MusicBeatState.switchState(new StoryMenuState());
							case 'freeplay':{
								persistentDraw = true;
								persistentUpdate = false;
								// Freeplay has its own custom transition
								FlxTransitionableState.skipNextTransIn = true;
								FlxTransitionableState.skipNextTransOut = true;

								openSubState(new FreeplayState());
								subStateOpened.addOnce(state -> {
									for (i in 0...menuItems.members.length) {
										menuItems.members[i].revive();
										menuItems.members[i].alpha = 1;
										menuItems.members[i].visible = true;
										selectedSomethin = false;
									}
									changeItem(0);
								});
							}
							case 'commands':
								MusicBeatState.switchState(new CommandsState());
							#if ACHIEVEMENTS_ALLOWED
							case 'awards':
								MusicBeatState.switchState(new AchievementsMenuState());
							#end
							case 'credits':
								MusicBeatState.switchState(new CreditsState());
							case 'options':
								MusicBeatState.switchState(new OptionsState());
								#if !LEGACY_PSYCH OptionsState.onPlayState = false; #end
								if (PlayState.SONG != null)
								{
									PlayState.SONG.arrowSkin = null;
									PlayState.SONG.splashSkin = null;
									#if !LEGACY_PSYCH PlayState.stageUI = 'normal'; #end
								}
						}
					});

					for (i in 0...menuItems.members.length)
					{
						if (i == curSelected)
							continue;
						FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								menuItems.members[i].kill();
							}
						});
					}
				}
			}
			if (#if TOUCH_CONTROLS_ALLOWED touchPad.buttonE.justPressed || #end 
				#if LEGACY_PSYCH FlxG.keys.anyJustPressed(ClientPrefs.keyBinds.get('debug_1').filter(s -> s != -1)) 
				#else controls.justPressed('debug_1') #end)
			{
				selectedSomethin = true;
				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		var item = menuItems.members[curSelected];
		FlxG.sound.play(Paths.sound('scrollMenu'));
		item.animation.play('idle');
		FlxTween.tween(item, {x: 130}, 0.14, {ease: FlxEase.quadOut, onComplete:
			item.updateHitbox
		});
		//menuItems.members[curSelected].screenCenter(X);

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		var curItem = menuItems.members[curSelected];
		curItem.animation.play('selected');
		FlxTween.tween(curItem, {x: curItem.x + 150}, 0.14, {ease: FlxEase.quadOut});
		//menuItems.members[curSelected].centerOffsets();
		//menuItems.members[curSelected].screenCenter(X);

		//camFollow.setPosition(menuItems.members[curSelected].getGraphicMidpoint().x,
		//	menuItems.members[curSelected].getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0));
	}
}
