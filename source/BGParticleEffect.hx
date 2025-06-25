package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup;

/**
 *  A full-screen, subtle gray dust particle effect.
 */
class BGParticleEffect extends FlxGroup
{
    public function new(amount:Int = 60)
    {
        super();

        for (i in 0...amount)
        {
            var size = FlxG.random.float(2, 4);
            var particle = new FlxSprite();
            particle.makeGraphic(Std.int(size), Std.int(size), 0xAA888888); // semi-transparent gray
            particle.x = FlxG.random.float(0, FlxG.width);
            particle.y = FlxG.random.float(0, FlxG.height);
            particle.velocity.x = FlxG.random.float(-10, -2); // slow leftward drift
            particle.velocity.y = FlxG.random.float(-8, -2);  // slow upward drift
            particle.alpha = FlxG.random.float(0.15, 0.35);   // subtle transparency
            add(particle);
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        for (sprite in members)
        {
            var particle = cast(sprite, FlxSprite);
            if (particle.x < -5 || particle.y < -5)
            {
                particle.x = FlxG.width + 5;
                particle.y = FlxG.random.float(0, FlxG.height);
                particle.velocity.x = FlxG.random.float(-10, -2);
                particle.velocity.y = FlxG.random.float(-8, -2);
                particle.alpha = FlxG.random.float(0.15, 0.35);
            }
        }
    }
}
