package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import backend.ui.PsychUIInputText;
import flixel.ui.FlxButton;

class CommandsState extends MusicBeatState
{
	// grande parte do código foi pego/baseado no CreditsState.hx e outros
	var bg:FlxSprite;
	
	private var commandsStuff:Array<Array<String>> = [];
	//private var grpCommands:FlxTypedGroup<Array<String>> = [];
	//var blockPressWhileTypingOn:FlxUIInputText = [];
	//var commandInputText:Array<FlxUIInputText>;

	override function create()
	{
		persistentUpdate = true;
		
		var bg = new FlxSprite().makeGraphic(1, 1, 0xFF36393F);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		//bg.screenCenter();
		add(bg);
		
		var commandsList:Array<Array<String>> = [
			['work'],
			['slut'],
			['crime'],
			['rob', 'steal'],
			['shop', 'store'],
			['russian-roullete', 'rr'],
			['blackjack', 'bj'],
			['help', '?']
		];

		/*for(i in commandsList) {
			commandsStuff.push(i);
		}*/
		// wip
		/*for(i in 0...commandsStuff.length) {
			var commandShit = "?" + commandsStuff[i][i];
		}*/

		//commandInputText = new FlxUIInputText(10, 30, 400, 'Conversar em #favela-dos-bots', 8);
		//blockPressWhileTypingOn.push(commandInputText);

		FlxG.sound.music.stop();
		FlxG.sound.playMusic(Paths.music('menuCommands'), 1.2, true); // playMusic('musicPath', volume, loop:Bool, 'group');
		/*sound.onComplete = function() {
			FlxG.sound.playMusic(Paths.music('freakyCommands'), 1);
		};*/

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('NONE', 'B');
		#end

		super.create();
	}
	var quitting:Bool = false;
	override function update(elapsed:Float)
	{
		if(!quitting)
		{
			if (controls.BACK)
			{
				//FlxG.sound.music.fadeOut(0.6, 0, { onComplete: function(twn:FlxTween) { // fadeOut(duration, toValue);
				//FlxG.sound.music.stop();
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.8);
				//}});
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				//blockPressWhileTypingOn.remove(commandInputText);
				quitting = true;
			}
		}
		super.update(elapsed);
	}
}
