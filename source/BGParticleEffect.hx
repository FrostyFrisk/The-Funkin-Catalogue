package;

import flixel.FlxG;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
 *  A full-screen particle effect emitting simple grey squares.
 */
class BGParticleEffect extends FlxEmitter
{
    public function new()
    {
        // Position emitter across bottom of screen
        super(0, FlxG.height - 10, 60); // 60 particles
        width  = FlxG.width;
        height = 10;

        // Create 60 square particles manually
        for (i in 0...60)
        {
            var size = FlxG.random.float(2, 4);
            var square = new FlxParticle();
            square.makeGraphic(Std.int(size), Std.int(size), FlxColor.WHITE);
            square.alpha = 0;
            square.color = 0xFF888888;
            add(square);
        }

        // Set velocity and rotation using setXSpeed/setYSpeed/setRotation for compatibility
        setXSpeed(-10, 10);
        setYSpeed(-80, -30);
        setRotation(0, 0);

        // No gravity
        // (FlxEmitter in 4.11.0 does not have a gravity property, so skip)

        // Continuous emission: lifespan 3s, frequency 0.05s, one per tick
        start(true, 3, 0.05, 1);
    }
}
