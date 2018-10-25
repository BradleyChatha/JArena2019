module jarena.gameplay.scenes.debugs.joshy_clicker;

private
{
    import std.format;
    import jarena.audio, jarena.core, jarena.gameplay, jarena.graphics, jarena.gameplay.scenes, jarena.maths;
}

@SceneName("Joshy Clicker")
final class JoshyClickerScene : Scene
{
    enum JOSHY_CLICKED_SCALE = 0.85;
    enum JOSHY_SCALE_SPEED = 0.30; // Per second
    enum SCORE_TEXT_POSITION = vec2(0, 50);
    enum SCORE_TEXT_CHARSIZE = 32;
    enum SCORE_TEXT_COLOUR   = Colour(0, 0, 0, 255);

    private
    {
        Sound _bding;
        StaticObject _joshy;
        TextObject _scoreText;
        size_t _score;
    }

    public override
    {
        void onInit()
        {
            this._bding = Systems.assets.get!Sound("Bding");
            this._joshy = new StaticObject(Systems.assets.get!Texture("tex_Joshy"));
            this._scoreText = new TextObject(Systems.assets.get!Font("Calibri"), "Score: 0", SCORE_TEXT_POSITION,
                                             SCORE_TEXT_CHARSIZE, SCORE_TEXT_COLOUR);
            super.register("Joshy", this._joshy);
            super.register("Score", this._scoreText);
        }

        void onSwap(PostOffice office)
        {
        }

        void onUnswap(PostOffice office)
        {
        }

        void onUpdate(Duration deltaTime, InputManager input)
        {
            // Slowly rescale Joshy back to 1.0
            if(this._joshy.scale.x < 1)
            {
                auto speed = JOSHY_SCALE_SPEED * deltaTime.asSeconds;
                this._joshy.scale = this._joshy.scale + vec2(speed);
                if(this._joshy.scale.x > 1)
                    this._joshy.scale = vec2(1);
            }

            // If Joshy is clicked, increase the score, play a sound, and then scale Joshy down
            if(this._joshy.bounds.contains(input.mousePosition) 
            && (   input.wasMouseButtonTapped(MouseButton.Left)
                || input.wasMouseButtonTapped(MouseButton.Right)))
            {
                this._score += 1;
                Systems.audio.play(this._bding);
                this._joshy.scale = vec2(JOSHY_CLICKED_SCALE);
                this._scoreText.text.text = format("Score: %s", this._score);
            }

            // Re-center Joshy
            this._joshy.position = vec2(  (Systems.window.size / uvec2(2, 2))
                                        - (uvec2(this._joshy.bounds.size) / uvec2(2, 2)));

            // Update the objects
            super.updateScene(deltaTime);
            super.updateUI(deltaTime);
        }

        void onRender(Window window)
        {
            super.renderScene(window);
            super.renderUI(window);
        }
    }
}
