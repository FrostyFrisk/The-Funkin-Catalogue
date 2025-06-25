package;

import flixel.FlxG;
import flixel.effects.FlxEmitter;
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
        super(0, FlxG.height - 10);
        width  = FlxG.width;
        height = 10;

        // Create 60 square particles manually
        var numParticles = 60;
        for (i in 0...numParticles)
        {
            // Create a small square sprite
            var size = FlxG.random.float(2, 4);
            var square = new FlxSprite()
                .makeGraphic(Std.int(size), Std.int(size), FlxColor.WHITE);
            square.alpha = 0; // start invisible until emitted
            add(square);
        }

        // Tint squares a light grey
        setColor(0xFF888888);

        // Velocity: upward drift with slight horizontal variance
        setXSpeed(-10, 10);
        setYSpeed(-80, -30);

        // No gravity
        gravity = 0;

        // No rotation for squares, or add slight if preferred
        setRotation(0, 0);

        // Continuous emission: lifespan 3s, frequency 0.05s, one per tick
        start(
            true,   // explode initial batch
            3,      // lifespan in seconds
            0.05,   // emission frequency (seconds)
            1       // particles per emission
        );
    }
}
