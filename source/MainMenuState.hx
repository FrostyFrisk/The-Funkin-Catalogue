package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.events.NetStatusEvent;
import BGParticleEffect;

using StringTools;

class MainMenuState extends MusicBeatState
{
    public static var psychEngineVersion:String = '0.6.2';
    public static var curSelected:Int = 0;
    // Removed introPlayed

    var menuItems:FlxTypedGroup<FlxText>;
    var selector:FlxSprite;
    var tvPos:FlxObject; // For camera zoom target
    // Removed introVideo

    var optionShit:Array<String> = [
        'story mode',
        'freeplay',
        'credits',
        'options'
    ];

    var magenta:FlxSprite;
    var camFollow:FlxObject;
    var camFollowPos:FlxObject;
    var debugKeys:Array<FlxKey>;
    var selectedSomethin:Bool = false;

    private var camGame:FlxCamera;
    private var camAchievement:FlxCamera;

    var tvWhiteScreen:FlxSprite;

    override function create()
    {
        trace('MainMenuState.create() called');
        #if MODS_ALLOWED
        Paths.pushGlobalMods();
        #end
        WeekData.loadTheFirstEnabledMod();
        #if desktop
        DiscordClient.changePresence("In the Menus", null);
        #end
        debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

        camGame = new FlxCamera();
        camAchievement = new FlxCamera();
        camAchievement.bgColor.alpha = 0;
        FlxG.cameras.reset(camGame);
        FlxG.cameras.add(camAchievement, false);
        FlxG.cameras.setDefaultDrawTarget(camGame, true);
        transIn = FlxTransitionableState.defaultTransIn;
        transOut = FlxTransitionableState.defaultTransOut;
        persistentUpdate = persistentDraw = true;

        // Background art
        var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('newmainmenuart/background'));
        bg.scrollFactor.set(0, 0.1);
        add(bg);
        // Dust particles
        add(new BGParticleEffect());

        // TV position for camera zoom
        tvPos = new FlxObject(900, 350, 1, 1); // Adjust to match TV center in your background
        add(tvPos);

        // Title and DEMO
        var titleText:FlxText = new FlxText(32, 32, 0, "the funkin' catalogue", 32);
        titleText.setFormat("VCR OSD Mono", 32, 0xFFC0C0C0, LEFT, FlxColor.BLACK);
        titleText.alpha = 0.7;
        add(titleText);
        var demoText:FlxText = new FlxText(titleText.x + titleText.width + 16, 40, 0, "DEMO", 28);
        demoText.setFormat("VCR OSD Mono", 28, 0xFF444444, LEFT, FlxColor.BLACK);
        demoText.alpha = 0.5;
        add(demoText);

        // Menu items (robust, no double add, no nulls)
        menuItems = new FlxTypedGroup<FlxText>();
        var menuStartY = 180;
        var menuGap = 70;
        var menuX = 180;
        for (i in 0...optionShit.length) {
            var labelText = optionShit[i].substr(0,1).toUpperCase() + optionShit[i].substr(1);
            var label = new FlxText(menuX, menuStartY + i * menuGap, 0, labelText, 48);
            label.setFormat("VCR OSD Mono", 48, FlxColor.WHITE, LEFT, FlxColor.BLACK);
            label.alpha = (i == 0) ? 1 : 0.4;
            label.bold = (i == 0);
            if (optionShit[i] == 'freeplay') {
                label.color = 0xFF888888;
                label.alpha = 0.6;
            } else {
                label.color = FlxColor.WHITE;
            }
            menuItems.add(label);
            trace('Menu item created and added: ' + labelText + ' at index ' + i + ' (label is null? ' + (label == null) + ')');
        }
        add(menuItems); // Add group after all items are in
        trace('All menu items added. menuItems.length=' + menuItems.length);

        // Selector setup
        selector = new FlxSprite(menuX - 50, menuStartY);
        selector.makeGraphic(18, 48, FlxColor.WHITE);
        selector.alpha = 1;
        add(selector);
        curSelected = 0;

        // Only call updateSelectionVisuals if menuItems is fully populated
        if (menuItems != null && menuItems.length == optionShit.length && selector != null && menuItems.members[curSelected] != null) {
            trace('Calling updateSelectionVisuals after menuItems creation');
            updateSelectionVisuals();
        } else {
            trace('Menu not ready for updateSelectionVisuals: menuItems=' + (menuItems == null) + ', selector=' + (selector == null) + ', menuItems.length=' + (menuItems != null ? menuItems.length : 'null') + ', curSelected=' + curSelected + ', menuItems.members[curSelected]=' + (menuItems != null && menuItems.members != null && curSelected < menuItems.members.length ? (menuItems.members[curSelected] == null) : 'n/a'));
        }
        FlxG.camera.follow(null);

        changeItem();

        // Version text (keep removed but here cause it was in the original and needs to be here)
        var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
        versionShit.scrollFactor.set();
        versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxColor.BLACK);
        //add(versionShit);
        versionShit = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
        versionShit.scrollFactor.set();
        versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxColor.BLACK);
        //add(versionShit);
        #if ACHIEVEMENTS_ALLOWED
        Achievements.loadAchievements();
        var leDate = Date.now();
        if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
            var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
            if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) {
                Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
                giveAchievement();
                ClientPrefs.saveSettings();
            }
        }
        #end

        // In create(), after adding tvPos:
        tvWhiteScreen = new FlxSprite(tvPos.x - 120, tvPos.y - 90).makeGraphic(240, 180, FlxColor.WHITE);
        tvWhiteScreen.visible = false;
        add(tvWhiteScreen);

        super.create();
    }

    #if ACHIEVEMENTS_ALLOWED
    // Unlocks "Freaky on a Friday Night" achievement
    function giveAchievement() {
        add(new AchievementObject('friday_night_play', camAchievement));
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
        trace('Giving achievement "friday_night_play"');
    }
    #end

    function updateSelectionVisuals():Void
    {
        trace('updateSelectionVisuals called');
        if (menuItems == null) { trace('menuItems is null!'); return; }
        if (menuItems.length == 0) { trace('menuItems.length == 0!'); return; }
        if (curSelected < 0 || curSelected >= menuItems.length) { trace('curSelected out of bounds: ' + curSelected); return; }
        for (i in 0...menuItems.length)
        {
            var label = menuItems.members[i];
            if (label == null) {
                trace('menuItems.members[' + i + '] is null!');
                continue;
            }
            if (optionShit[i] == 'freeplay') {
                label.color = 0xFF888888;
                label.alpha = 0.6;
            } else {
                label.alpha = (i == curSelected) ? 1 : 0.4;
                label.color = FlxColor.WHITE;
            }
            label.bold = (i == curSelected);
        }
        var selectedLabel:FlxText = null;
        if (curSelected >= 0 && curSelected < menuItems.length)
            selectedLabel = menuItems.members[curSelected];
        if (selector == null) {
            trace('selector is null!');
        }
        if (selectedLabel == null) {
            trace('selectedLabel is null!');
        }
        // Fix: Only use selector.x/y if both are not null and are valid floats
        if (selector != null && selectedLabel != null) {
            selector.x = selectedLabel.x - 50;
            selector.y = selectedLabel.y;
            selector.visible = true;
        }
    }

    function changeItem(delta:Int = 0):Void
    {
        trace('changeItem called with delta=' + delta);
        if (menuItems == null) { trace('menuItems is null!'); return; }
        if (menuItems.length == 0) { trace('menuItems.length == 0!'); return; }
        curSelected = (curSelected + delta + menuItems.length) % menuItems.length;
        trace('curSelected now: ' + curSelected);
        updateSelectionVisuals();
    }

    var transitioning:Bool = false;
    var nextState:MusicBeatState = null;
    function onSelect():Void
    {
        trace('onSelect called');
        if (transitioning) { trace('Already transitioning, return'); return; }
        if (menuItems == null) { trace('menuItems is null!'); return; }
        if (menuItems.members == null) { trace('menuItems.members is null!'); return; }
        if (curSelected < 0 || curSelected >= menuItems.members.length) { trace('curSelected out of bounds: ' + curSelected); return; }
        var selectedLabel = menuItems.members[curSelected];
        if (selectedLabel == null) { trace('selectedLabel is null!'); }
        if (optionShit[curSelected] == 'freeplay') {
            // Play error/locked SFX and shake the menu item
            FlxG.sound.play(Paths.sound('cancelMenu'));
            if (selectedLabel != null) {
                FlxFlicker.flicker(selectedLabel, 0.4, 0.05, true, false);
            }
            return;
        }
        // In onSelect(), replace the 'story mode' case:
        if (optionShit[curSelected] == 'story mode') {
            if (transitioning) { trace('Already transitioning (story mode), return'); return; }
            transitioning = true;
            // Show and flicker the white screen on the TV
            if (tvWhiteScreen == null) { trace('tvWhiteScreen is null!'); }
            else tvWhiteScreen.visible = true;
            if (tvWhiteScreen != null) {
                FlxFlicker.flicker(tvWhiteScreen, 0.5, 0.08, true, false, function(_) {
                    if (tvPos == null) { trace('tvPos is null!'); }
                    else FlxG.camera.focusOn(tvPos.getPosition());
                    FlxTween.tween(FlxG.camera, {zoom: 2.2}, 0.5, {
                        ease: FlxEase.cubeIn,
                        onComplete: function(_) {
                            trace('Loading Newsflash song');
                            if (PlayState == null) { trace('PlayState is null!'); }
                            PlayState.SONG = Song.loadFromJson("newsflash", "newsflash");
                            PlayState.isStoryMode = false;
                            PlayState.storyDifficulty = 1; // or 0 for easy
                            LoadingState.loadAndSwitchState(new PlayState());
                        }
                    });
                });
            }
            return;
        }
        transitioning = true;
        // Camera zoom to TV, then switch state
        if (tvPos == null) { trace('tvPos is null!'); }
        else FlxG.camera.focusOn(tvPos.getPosition());
        FlxTween.tween(FlxG.camera, {zoom: 2.2}, 0.6, {
            ease: FlxEase.cubeIn,
            onComplete: function(_) {
                trace('Switching state for option: ' + optionShit[curSelected]);
                switch (optionShit[curSelected])
                {
                    case 'story mode':
                        MusicBeatState.switchState(new StoryMenuState());
                    case 'credits':
                        MusicBeatState.switchState(new CreditsState());
                    case 'options':
                        LoadingState.loadAndSwitchState(new options.OptionsState());
                }
            }
        });
    }

    override function update(elapsed:Float)
    {
        if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
        {
            FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
            if(FreeplayState != null && FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
        }
        if (!selectedSomethin && !transitioning)
        {
            if (FlxG.keys.justPressed.UP)    changeItem(-1);
            if (FlxG.keys.justPressed.DOWN)  changeItem( 1);
            if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
                onSelect();
            if (controls != null && controls.ACCEPT)
            {
                onSelect();
            }
            #if desktop
            else if (FlxG.keys.anyJustPressed(debugKeys))
            {
                selectedSomethin = true;
                MusicBeatState.switchState(new MasterEditorMenu());
            }
            #end
        }
        super.update(elapsed);
        if (menuItems != null) {
            menuItems.forEach(function(spr:FlxSprite)
            {
                if (spr == null) {
                    trace('menuItems.forEach: spr is null!');
                    return;
                }
                spr.screenCenter(X);
            });
        } else {
            trace('menuItems is null in update!');
        }
    }
}