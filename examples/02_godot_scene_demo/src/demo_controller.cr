require "lapis"
require "../../../src/emerald"

# Controller node connecting Godot UI buttons to EmeraldVideoPlayer
node DemoController < Control do
  @player : EmeraldVideoPlayer? = nil
  @btn_play_pause : Godot::Button? = nil
  @btn_stop : Godot::Button? = nil
  @slider_progress : Godot::HSlider? = nil
  @slider_volume : Godot::HSlider? = nil
  @lbl_time : Godot::Label? = nil

  def _ready : Void
    @player = get_node_as(EmeraldVideoPlayer, "EmeraldVideoPlayer")
    @btn_play_pause = get_node_as(Godot::Button, "ControlsPanel/ControlsBox/PlayPauseButton")
    @btn_stop = get_node_as(Godot::Button, "ControlsPanel/ControlsBox/StopButton")
    @slider_progress = get_node_as(Godot::HSlider, "ControlsPanel/ControlsBox/ProgressBar")
    @slider_volume = get_node_as(Godot::HSlider, "ControlsPanel/ControlsBox/VolumeSlider")
    @lbl_time = get_node_as(Godot::Label, "ControlsPanel/ControlsBox/TimeLabel")

    # Wire up button presses
    @btn_play_pause.try(&.pressed.connect do
      if p = @player
        p.toggle_pause
        update_play_pause_button
      end
    end)

    @btn_stop.try(&.pressed.connect do
      @player.try(&.stop)
      update_play_pause_button
    end)

    # Wire up volume slider
    @slider_volume.try(&.value_changed.connect do |val|
      @player.try(&.volume = val.to_i32)
    end)

    # Connect player signals
    if p = @player
      p.playback_started.connect { update_play_pause_button }
      p.playback_paused.connect { update_play_pause_button }
      p.playback_stopped.connect { update_play_pause_button }

      p.position_changed.connect do |pos_pct, time_ms|
        @slider_progress.try(&.set_value_no_signal(pos_pct))
        update_time_label(time_ms, p.player.try(&.length_ms) || 0_i64)
      end
    end
  end

  private def update_play_pause_button : Void
    if p = @player
      txt = p.playing? ? "⏸ Pause" : "▶ Play"
      @btn_play_pause.try(&.text = txt)
    end
  end

  private def update_time_label(current_ms : Int64, total_ms : Int64) : Void
    cur_str = format_ms(current_ms)
    tot_str = total_ms > 0 ? format_ms(total_ms) : "--:--"
    @lbl_time.try(&.text = "#{cur_str} / #{tot_str}")
  end

  private def format_ms(ms : Int64) : String
    total_sec = ms // 1000
    min = total_sec // 60
    sec = total_sec % 60
    sprintf("%02d:%02d", min, sec)
  end
end
