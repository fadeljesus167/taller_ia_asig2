class DotsBoxes
  attr_accessor :rows, :columns, :play_dict
  def initialize(rows, columns)
    @rows = rows
    @columns = columns

    @play_dict = {}
  end

  def render_row(row_number)
    left = row_number * columns
    right = left + 1

    columns.times do
      if play_dict[[left,right]].eql?(0)
        puts " #{left} "
      else
        puts " #{left}  -"
      end
      left = right
      right = left + 1
    end
    puts " #{left} "
  end

  def render_vertical(upper_left, upper_right)
    if play_dict[[upper_left, upper_right]].eql?(0)
      puts "   "
    else
      puts " | "
    end
  end

  def render_middle_row(row_number)
    upper_left = row_number * columns
    upper_right = upper_left + 1
    bottom_left = upper_left + columns
    bottom_right = bottom_left + 1

    columns.times do
      render_vertical(upper_left, upper_right)

      top = [upper_left, upper_right]
      left = [upper_left, bottom_left]
      right = [upper_right, bottom_right]
      bottom = [bottom_left, bottom_right]

      score = score_dict[[top, left, right, bottom]]

      if score.eql?(0)
        puts "  "
      else
        puts " " + score + " "
      end

      upper_left, bottom_left = upper_right, bottom_right
      upper_right += 1
      bottom_right += 1
    end
    render_vertical(upper_left, bottom_left)
  end

  def render
    rows.times do |row_number|
      puts "Iteration #{row_number}"
      render_row(row_number)
      render_middle_row(row_number)
    end

    render_row
  end
end

class Game
  attr_accessor :player_a, :player_b, :rows, :columns
  def initialize(player_a, player_b, rows=5, columns=5)
    player_a = player_a
    player_b = player_b
    @rows = rows
    @columns = columns
  end

  def play_game
    game = DotsBoxes.new(rows, columns)
    game.render()
  end
end

game = Game.new("Fadel", "AI", 6, 6)
game.play_game
