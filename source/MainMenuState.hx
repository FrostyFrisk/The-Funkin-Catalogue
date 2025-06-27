package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxState;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.FlxObject;

// Import the BGParticleEffect class
import BGParticleEffect;

class MainMenuState extends FlxState
{
    public static var psychEngineVersion:String = "Psych Engine v0.6.3";
    
    var menuItems:FlxTypedGroup<FlxText>;
    var selector:FlxSprite;
    var options:Array<String> = ['Play', 'Freeplay', 'Options', 'Credits'];
    var curSelected:Int = 0;
    var transitioning:Bool = false;
    var wallBg:FlxSprite;
    var tvSprite:FlxSprite;
    var dresser:FlxSprite;
    var titleText:FlxText;
    var demoText:FlxText;
    var moveSfx:FlxSound;
    var confirmSfx:FlxSound;
    var versionShit:String = "v1.0.0";
    var errorSfx:FlxSound;
    var mainCam:FlxCamera;
    var fadeOverlay:FlxSprite;
    var lastInputTime:Float = 0;
    var inputCooldown:Float = 0.12;
    var tvFlickerGlow:FlxSprite;

    // Add a variable for the particle effect
    var bgParticles:BGParticleEffect;

    override public function create():Void
    {
        super.create();

        // Camera
        mainCam = new FlxCamera();
        FlxG.cameras.reset(mainCam);
        FlxG.cameras.setDefaultDrawTarget(mainCam, true);

        // Play menu music
        FlxG.sound.playMusic(Paths.music("TFCMenu"), 1, true);
        
        // --- Layered Art Assets ---

        // 1. menuBG_dark (full background)
        wallBg = new FlxSprite().loadGraphic("assets/images/newmainmenuart/thewall.png");
        wallBg.antialiasing = true;
        wallBg.scrollFactor.set(0, 0);
        add(wallBg);

        // BG Particle Effect (behind every other but not behind the wall)
        bgParticles = new BGParticleEffect();
        add(bgParticles);

        // 2. menuBG_overlay (left faded overlay for menu)
        var bgOverlay = new FlxSprite().loadGraphic("assets/images/newmainmenuart/menuitemsholder.png");
        bgOverlay.antialiasing = true;
        bgOverlay.scrollFactor.set(0, 0);
        add(bgOverlay);

        // 5. menu_tv (TV)
        tvSprite = new FlxSprite().loadGraphic("assets/images/newmainmenuart/tvoff.png");
        tvSprite.antialiasing = true;
        tvSprite.scrollFactor.set(0, 0);
        add(tvSprite);

        // 6. menu_tv_white (TV white screen, hidden by default)
        var tvWhite = new FlxSprite(tvSprite.x, tvSprite.y).loadGraphic("assets/images/newmainmenuart/tvon.png");
        tvWhite.antialiasing = true;
        tvWhite.scrollFactor.set(0, 0);
        tvWhite.visible = false;
        add(tvWhite);

        // 7. menu_flickerglow (TV flicker, hidden by default)
        tvFlickerGlow = new FlxSprite(tvSprite.x, tvSprite.y).loadGraphic("assets/images/newmainmenuart/tvflickerglow.png");
        tvFlickerGlow.antialiasing = true;
        tvFlickerGlow.scrollFactor.set(0, 0);
        tvFlickerGlow.visible = false;
        add(tvFlickerGlow);

        // 3. menuBG_filter (blue filter overlay)
        var filter = new FlxSprite().loadGraphic("assets/images/newmainmenuart/bluefilter.png");
        filter.antialiasing = true;
        filter.scrollFactor.set(0, 0);
        add(filter);

        //    Cinematic Bars
        var cinematicBars = new FlxSprite().loadGraphic("assets/images/newmainmenuart/cinematicbars.png");
        cinematicBars.antialiasing = true;
        cinematicBars.scrollFactor.set(0, 0);
        add(cinematicBars);

        // --- Logo Text ---
        titleText = new FlxText(40, 60, 0, "the funkin' catalogue", 32);
        titleText.setFormat("VCR OSD Mono", 32, FlxColor.GRAY, "left");
        titleText.alpha = 0.8;
        add(titleText);
        demoText = new FlxText(320, 90, 0, "DEMO", 32);
        demoText.setFormat("VCR OSD Mono", 32, FlxColor.GRAY, "left");
        demoText.alpha = 0.5;
        add(demoText);

        // Menu items
        menuItems = new FlxTypedGroup<FlxText>();
        var startY = 180;
        var gap = 70;
        for (i in 0...options.length)
        {
            var txt = new FlxText(80, startY + i * gap, 0, options[i], 48);
            txt.setFormat("VCR OSD Mono", 48, (i == 1) ? FlxColor.GRAY : FlxColor.WHITE, "left");
            txt.alpha = (i == curSelected) ? 1 : ((i == 1) ? 0.4 : 0.7);
            txt.bold = (i == curSelected);
            menuItems.add(txt);
        }
        add(menuItems);

        // Selector (rectangle bar)
        selector = new FlxSprite(48, startY + curSelected * gap + 8);
        selector.makeGraphic(16, 48, FlxColor.GRAY);
        selector.alpha = 0.8;
        add(selector);

        // Fade overlay for transitions
        fadeOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        fadeOverlay.alpha = 0;
        fadeOverlay.scrollFactor.set();
        add(fadeOverlay);

        // Sounds
        moveSfx = FlxG.sound.load("assets/sounds/menu_move.ogg");
        confirmSfx = FlxG.sound.load("assets/sounds/menu_select.ogg");
        errorSfx = FlxG.sound.load("assets/sounds/menu_error.ogg");

        updateSelection();
    }

    function updateSelection():Void
    {
        for (i in 0...menuItems.length)
        {
            var txt = menuItems.members[i];
            if (i == 1) { // Freeplay is locked
                txt.alpha = 0.4;
                txt.color = FlxColor.GRAY;
            } else {
                txt.alpha = (i == curSelected) ? 1 : 0.7;
                txt.color = (i == curSelected) ? FlxColor.WHITE : FlxColor.GRAY;
            }
            txt.bold = (i == curSelected);
        }
        var selected = menuItems.members[curSelected];
        selector.y = selected.y + 8;
    }

    function changeSelection(delta:Int):Void
    {
        if (transitioning) return;
        var prev = curSelected;
        do {
            curSelected = (curSelected + delta + options.length) % options.length;
        } while (curSelected == 1); // skip Freeplay (locked)
        if (prev != curSelected) {
            moveSfx.play(true);
            updateSelection();
        }
    }

    function selectOption():Void
    {
        if (transitioning) return;
        if (curSelected == 1) { // Freeplay locked
            errorSfx.play(true);
            return;
        }
        transitioning = true;
        confirmSfx.play(true);

        switch (curSelected)
        {
            case 0: // Play
                fadeIn(function() {
                    FlxG.switchState(new PlayState());
                });
            case 2: // Options
                fadeIn(function() {
                    FlxG.switchState(new options.OptionsState());
                });
            case 3: // Credits
                fadeIn(function() {
                    FlxG.switchState(new CreditsState());
                });
        }
    }

    function showFlickerGlow():Void {
        tvFlickerGlow.visible = true;
        tvFlickerGlow.alpha = 1;
        FlxTween.tween(tvFlickerGlow, {alpha: 0}, 0.18, {
            ease: FlxEase.quadIn,
            onComplete: function(_) tvFlickerGlow.visible = false
        });
    }

    function fadeIn(callback:Void->Void):Void {
        fadeOverlay.alpha = 0;

        // Calculate the center of the TV sprite in screen coordinates
        var tvCenterX = tvSprite.x + tvSprite.width / 2;
        var tvCenterY = tvSprite.y + tvSprite.height / 2;

        // Target camera zoom and scroll so that TV center stays centered on screen
        var targetZoom = 2;
        var targetScrollX = tvCenterX - (FlxG.width / (2 * targetZoom));
        var targetScrollY = tvCenterY - (FlxG.height / (2 * targetZoom));

        // Tween camera zoom and position to focus on TV, slower duration
        FlxTween.tween(mainCam, {zoom: targetZoom}, 1.0, {
            ease: FlxEase.quadInOut
        });
        FlxTween.tween(mainCam.scroll, {x: targetScrollX, y: targetScrollY}, 1.0, {
            ease: FlxEase.quadInOut
        });

        // Flicker effect on TV
        showFlickerGlow();

        // Turn TV ON (show tvWhite, hide tvSprite)
        tvSprite.visible = false;
        // Find the tvWhite sprite (added after tvSprite)
        var tvWhite:FlxSprite = null;
        for (sprite in members) {
            if (Std.isOfType(sprite, FlxSprite)) {
                var spr = cast(sprite, FlxSprite);
                if (spr.graphic != null && spr.graphic.key != null && spr.graphic.key.indexOf("tvon.png") != -1) {
                    tvWhite = spr;
                    break;
                }
            }
        }
        if (tvWhite != null) tvWhite.visible = true;

        // Fade to black overlay, slower duration
        FlxTween.tween(fadeOverlay, {alpha: 1}, 1.0, {
            ease: FlxEase.quadIn,
            onComplete: function(_) callback()
        });
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        if (!transitioning)
        {
            if (FlxG.keys.anyJustPressed([FlxKey.UP, FlxKey.W])) changeSelection(-1);
            if (FlxG.keys.anyJustPressed([FlxKey.DOWN, FlxKey.S])) changeSelection(1);
            if (FlxG.keys.anyJustPressed([FlxKey.ENTER, FlxKey.SPACE])) selectOption();
        }
    }
}
