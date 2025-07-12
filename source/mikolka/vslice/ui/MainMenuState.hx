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
	var allowMouse:Bool = false; // crashando o jogo no momento

	var bottom:FlxTypedGroup<FlxSprite>;
	var profileBottomBG:FlxSprite;
	
	var menuItems:FlxTypedGroup<FlxSprite>;
	var menuItemsText:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<Array<String>> = [
	// 'nome',				'nomeDisplay',			'emoji'
		['story_mode',	'modo-história-',		'open-book'],
		['freeplay',		'freeplay-',				'unlocked'],
		['commands',		'favela-dos-bots-',	'robot'], // favela-dos-bots
		['awards',			'conquistas-',			'trophy'],
		['credits',			'créditos-',				'handshake'],
		['options'] // separado do resto
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
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mainmenu/menuBG'));
		bg.antialiasing = false;
		bg.scrollFactor.set();
		//bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		//add(camFollow);

		bottom = new FlxTypedGroup<FlxSprite>();
		add(bottom);
		
		profileBottomBG = new FlxSprite(10, FlxG.height - 110).loadGraphic(Paths.image('mainmenu/profileBottomBG'));
		profileBottomBG.antialiasing = false;
		bottom.add(profileBottomBG);
		profileBottomBG.scrollFactor.set();
		profileBottomBG.updateHitbox();
		
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);
		menuItemsText = new FlxTypedGroup<FlxSprite>();
		add(menuItemsText);

		for (i in 0...5)
		{
			// base das opções
			var menuItem:FlxSprite = new FlxSprite(132, (i * 59) + 200);
			menuItem.antialiasing = false; //VsliceOptions.ANTIALIASING
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/buttons/menu_base');
			menuItem.animation.addByPrefix('idle', "option basic", 0);
			menuItem.animation.addByPrefix('selected', "option chosen", 0);
			menuItem.animation.addByPrefix('clicked', "option click", 0);
			menuItem.animation.play('idle');
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.updateHitbox();
			
			// textos e emojis das opções
			var menuItemText:FlxText;
			var menuItemEmoji:FlxSprite;
			
			if (optionShit[i][1] != null) {
				menuItemText = new FlxText(190, (i * 59) + 220, FlxG.width, optionShit[i][1], 26);
				menuItemText.setFormat(Paths.font("ggsans/semibold.ttf"), 26, 0xFF9B9CA3, LEFT);
				menuItemsText.add(menuItemText);
				menuItemText.scrollFactor.set();
				menuItemText.updateHitbox();
				if (optionShit[i][2] != null) {
					menuItemEmoji = new FlxSprite(menuItemText.x + 60, menuItemText.y).loadGraphic(optionShit[i][2]);
					//menuItemsText.add(menuItemEmoji);
					menuItemEmoji.scrollFactor.set();
					menuItemEmoji.updateHitbox();
				}
			}
		}
		
		// botão de opções
		var optionsButton:FlxSprite = new FlxSprite(460, profileBottomBG.y + 22);
		optionsButton.antialiasing = false;
		optionsButton.frames = Paths.getSparrowAtlas('mainmenu/buttons/menu_options');
		optionsButton.animation.addByPrefix('idle', "options basic", 0);
		optionsButton.animation.addByPrefix('selected', "options chosen", 0);
		optionsButton.animation.play('idle');
		menuItems.add(optionsButton);
		optionsButton.scrollFactor.set();
		optionsButton.updateHitbox();
		
		var psychVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, "P-Slice Engine v" + pSliceVersion, 12);
		var vsfVer:FlxText = new FlxText(0, 12, FlxG.width, "Vs. Server Foda v" + vsfVersion, 24);
		
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		vsfVer.setFormat(Paths.font("ggsans/medium.ttf"), 24, 0xFFDFE0E2, CENTER); //, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
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
		addTouchPad('UP_DOWN', 'A_B_E'); // tirar o '_E' na versão final!!!!!!!!!!
		#end

		super.create();

		//FlxG.camera.follow(camFollow, null, 0.06);
	}

	var selectedSomethin:Bool = false;

	var timeNotMoving:Float = 0;
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

			var allowMouse:Bool = allowMouse;
			if (allowMouse && ((FlxG.mouse.deltaViewX != 0 && FlxG.mouse.deltaViewY != 0) || FlxG.mouse.justPressed)) //FlxG.mouse.deltaViewX/Y checks is more accurate than FlxG.mouse.justMoved
			{
				allowMouse = false;
				FlxG.mouse.visible = true;
				timeNotMoving = 0;

				var selectedItem:FlxSprite;
				selectedItem = menuItems.members[curSelected];

				var dist:Float = -1;
				var distItem:Int = -1;
				for (i in 0...optionShit.length)
				{
					var memb:FlxSprite = menuItems.members[i];
					if(FlxG.mouse.overlaps(memb))
					{
						var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.viewX, 2) + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.viewY, 2));
						if (dist < 0 || distance < dist)
						{
							dist = distance;
							distItem = i;
							allowMouse = true;
						}
					}
				}

				if(distItem != -1 && selectedItem != menuItems.members[distItem])
				{
					curSelected = distItem;
					changeItem();
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if(timeNotMoving > 2) FlxG.mouse.visible = false;
			}
			
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT || (FlxG.mouse.overlaps(menuItems) && FlxG.mouse.justPressed && allowMouse))
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;

				selectedSomethin = true;
				if (curSelected != menuItems.length - 1)
					menuItems.members[curSelected].animation.play('clicked');
				FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					switch (optionShit[curSelected][0])
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
		var curItem = menuItems.members[curSelected];
		var item = curItem; // essa não é pra atualizar
		var curItemText = menuItemsText.members[curSelected];
		var itemText = curItemText; // nem essa
		FlxG.sound.play(Paths.sound('scrollMenu'));
		item.animation.play('idle');
		item.updateHitbox();
		if (curSelected != menuItems.length - 1) {
			itemText.color = 0xFF9B9CA3;
			FlxTween.tween(itemText, {x: 190}, 0.14, {ease: FlxEase.quadOut});
			FlxTween.tween(item, {x: 132}, 0.14, {
				ease: FlxEase.quadOut,
				onComplete: function(twn:FlxTween) { item.updateHitbox(); }
			});
		} else {
			FlxTween.tween(item, {y: profileBottomBG.y + 22}, 0.14, {
				ease: FlxEase.quadOut,
				onComplete: function(twn:FlxTween) { item.updateHitbox(); }
			});
		}
		//menuItems.members[curSelected].screenCenter(X);

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		var isOptionsSelected:Bool = false; // mais fácil
		if (curSelected == menuItems.length - 1)
			isOptionsSelected = true;
		else
			isOptionsSelected = false;

		curItem = menuItems.members[curSelected];
		curItemText = menuItemsText.members[curSelected];
		curItem.animation.play('selected');
		curItem.updateHitbox();
		if (!isOptionsSelected) {
			curItemText.color = FlxColor.WHITE;
			FlxTween.tween(curItemText, {x: 208}, 0.14, {ease: FlxEase.quadOut});
			FlxTween.tween(curItem, {x: 150}, 0.14, {
				ease: FlxEase.quadOut,
				onComplete: function(twn:FlxTween) { curItem.updateHitbox(); }
			});
		} else {
			FlxTween.tween(curItem, {y: profileBottomBG.y + 14}, 0.14, {
				ease: FlxEase.quadOut,
				onComplete: function(twn:FlxTween) { curItem.updateHitbox(); }
			});
		}
		//menuItems.members[curSelected].centerOffsets();
		//menuItems.members[curSelected].screenCenter(X);

		//camFollow.setPosition(menuItems.members[curSelected].getGraphicMidpoint().x,
		//	menuItems.members[curSelected].getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0));
	}
}
