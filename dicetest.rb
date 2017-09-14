class Die
    def initialize
        @faces = [ :plus, :plus, :neutral, :neutral, :minus, :minus ]
    end

    def roll
        @faces[rand(0..5)]
    end

    def roll_dice(dice: 1, approach: method(:approach_2))
        rolls = dice.times.map{roll}
        approach.call(rolls)
    end

    def roll_dice_times(dice: 2, times: 1000000, approach: method(:approach_2))
        results = Hash.new(0)
        times.times do
            results[roll_dice(dice: dice, approach:approach)] += 1
        end

        puts "Rolled #{dice} dice #{times} times"
        puts "Plus: #{results[:plus]/(times*1.0)} Neutral: #{results[:neutral]/(times*1.0)} Minus: #{results[:minus]/(times*1.0)}"
    end
end

def toNum(roll)
    case roll
    when :plus
        return 1
    when :neutral
        return 0
    when :minus
        return -1
    else
        puts "WTF: #{roll}"
    end
end

def mathy(rolls)
    sum = rolls.inject(0) { |c, roll| c += toNum(roll) }
    return :plus if sum > 0
    return :minus if sum < 0
    return :neutral if sum == 0
end

def approach_2(rolls)
    return :plus if rolls.any?{ |r| r == :plus}
    return :neutral if rolls.all? { |r| r == :neutral }
    return :minus if rolls.any? { |r| r == :minus }
end


if __FILE__ == $PROGRAM_NAME
    die= Die.new
    puts "mathy"
    die.roll_dice_times(approach: method(:mathy))
    puts "smarter"
    die.roll_dice_times(approach: method(:approach_2))
end
