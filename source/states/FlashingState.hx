package states;

import flixel.FlxSubState;

import flixel.effects.FlxFlicker;
import flixel.addons.display.FlxBackdrop;
import lime.app.Application;
import objects.TypedAlphabet;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var bg:FlxSprite;
	var backdrop:FlxBackdrop;
	var bigText:Alphabet;
	var warnText:FlxText;
	
	override function create()
	{
		controls.isInSubstate = false; // qhar I hate it
		super.create();

		var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLUE);
		bg.alpha = 0.05;
		add(bg);
		
		backdrop = new FlxBackdrop(Paths.image('backdrop_sanes'));
		backdrop.setGraphicSize(Std.int(backdrop.width * 0.6));
		backdrop.alpha = 0.20;
		backdrop.antialiasing = ClientPrefs.data.antialiasing;
		backdrop.screenCenter(X);
		backdrop.updateHitbox();
		add(backdrop);
		
		bigText = new Alphabet(0, 120, 'Cuidado!', true);
		bigText.screenCenter(X);
		add(bigText);

		final enter:String = controls.mobileC ? 'A' : 'ENTER';
		final escape:String = controls.mobileC ? 'B' : 'ESC';

		warnText = new FlxText(0, (FlxG.height / 2) - 40, FlxG.width,
			"Este mod contém algumas luzes piscantes!\n
			Aperte " + enter + " para desativá-las agora ou abra o menu de opções.\n
			Aperte " + escape + " para ignorar esta mensagem.\n
			Você foi avisado(a)!",
			32);
		warnText.setFormat(Paths.font("comic_sans.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warnText.screenCenter(X);
		add(warnText);
		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('NONE', 'A_B');
		#end
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			// https://gamebanana.com/tuts/15426
			backdrop.x -= 0.3 * (elapsed / (1 / 120));
			backdrop.y += 0.2 / (ClientPrefs.data.framerate / 60);
			
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				
				FlxTween.tween(bg, {alpha: 0}, 1.2);
				FlxTween.tween(backdrop, {alpha: 0}, 1.2);
				#if TOUCH_CONTROLS_ALLOWED FlxTween.tween(touchPad, {alpha: 0}, 1); #end
				if(!back) {
					ClientPrefs.data.flashing = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxG.camera.flash(0x4CFFFFFF, 1);
					FlxFlicker.flicker(bigText, 1, 0.1, false, true);
					FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
						new FlxTimer().start(0.5, function (tmr:FlxTimer) {
							MusicBeatState.switchState(new TitleState());
						});
					});
				} else {
					ClientPrefs.data.flashing = true;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxTween.tween(bigText, {alpha: 0}, 1);
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function (twn:FlxTween) {
							MusicBeatState.switchState(new TitleState());
						}
					});
				}
			}
		}
		super.update(elapsed);
	}
}
