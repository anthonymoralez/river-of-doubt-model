require_relative "dicetest"
class Player
    attr_accessor :health
    def initialize(name, max_health, bonus)
        @name = name
        @max_health = @health = max_health
        @dice_cup = Die.new
        @hand = { river: [], jungle: [] }
        @actions = { fishing: 0, hunting: 0, healing: 0}
        @bonus = { fishing: (bonus[:fishing] or 0),
                   hunting: (bonus[:hunting] or 0),
                   healing: (bonus[:healing] or 0),
                   rafting: (bonus[:rafting] or 0) }
    end
    def take_illness(count: 1)
        if count > @health
            @health = 0
            return count - @health
        else
            @health -= count
            return 0
        end
    end
    def run_rapids(river)
        #puts "\tRunning rapids"
        action(river, :river, @bonus[:rafting])
    end
    def draw(deck, type)
        drawn_card = deck.draw
        if drawn_card.first == :death
            take_illness(count: @max_health / 3)
        end
        drawn_card
    end
    def action(deck, type, bonus)
        roll = @dice_cup.roll_dice(dice:1+bonus)
        return roll if deck.empty?

        drawn_card = draw(deck, type)
        case roll
        when :plus
            @hand[type].push(drawn_card)
        when :neutral
            @hand[type].push(drawn_card)
            take_illness(count: drawn_card.last)
        when :minus
            take_illness(count: drawn_card.last)
        end
        #puts "\t#{@name} rolled #{roll} and drew #{drawn_card.first} with #{drawn_card.last}"
        roll
    end
    def take_action(river, jungle)
        if @health <= (@max_health * 0.65)
            #puts "\tHealing..."
            @actions[:healing] += 1
            roll = @dice_cup.roll_dice(dice:1+@bonus[:healing])
            case roll
            when :plus
                #puts "\t#{@name} rolled #{roll} and healed"
                take_illness(count: -2)
            when :neutral
                #puts "\t#{@name} rolled #{roll} and nothing happened"
            when :minus
                #puts "\t#{@name} rolled #{roll} and consumed provisions"
                return -1
            end
        else
            case rand(0..1)
            when 0
                @actions[:fishing] += 1
                #puts "\tFishing..."
                if [:plus, :neutral].include? action(river, :river, @bonus[:fishing])
                    return 1
                end
            when 1
                @actions[:hunting] += 1
                #puts "\tHunting..."
                if [:plus, :neutral].include? action(jungle, :jungle, @bonus[:hunting])
                    return 1
                end
            end
        end
        return 0
    end
    def healed(count: 2)
        @healed += count
    end
    def is_dead?
        @health == 0
    end

    def hand_to_a
        @hand.map { |type, cards|
            "#{type}: #{cards.group_by { |card| card.first }.map { |symbol, c|
                "#{symbol}: #{c.count}"
            }}"
        }
    end
    def to_s
        return """#{@name}: #{@health}:
        { fish: #{@actions[:fishing]}, hunt: #{@actions[:hunting]}, heal: #{@actions[:healing]} }
        { #{hand_to_a.join "\n\t\t  " } }
"""

    end
end

class Deck
    def initialize(death: 2, plus: 5, neutral: 15, minus: 10)
        @original_cards = []
        @original_cards.concat(death.times.map { [:death, rand(0..4)] })
        @original_cards.concat(plus.times.map { [:plus, 0] })
        @original_cards.concat(neutral.times.map { [:neutral,rand(0..3)] })
        @original_cards.concat(minus.times.map { [:minus, rand(2..4)] })
        @cards = @original_cards.shuffle
    end
    def draw
        @cards.shift
    end
    def empty?
        @cards.empty?
    end
    def to_s
        "#{@cards.size} remaining"
    end
end

class Game
    def initialize
        @river_tiles = [ :rapids, :rapids, :still ]
        @players = [Player.new(:Kermit, 15, hunting:1, fishing:1),
                    Player.new(:Rondon, 17, rafting:1, healing:1),
                    Player.new(:Roosevelt, 13, hunting:1, fishing:1),
                    Player.new(:Cherrie, 15, hunting: 1, rafting:1)]
        @jungle = Deck.new(death:1, plus:4, neutral:4, minus:4)
        @river = Deck.new(death:3, plus:12, neutral:12, minus:12)
        @provisions = 20
        @turn = 0
    end

    def turn()
        @turn+=1
        river_tile = @river_tiles[rand(0..2)]
        #puts "Turn #{count}: #{river_tile}"
        #puts "\tProvision remaining: #{@provisions}"
        if river_tile == :rapids
            run_rapids
        else
            still_water_turn()
        end
        @provisions -= 1
        if @players.all? { |p| p.is_dead? } or @provisions <= 0
            #puts "Everyone is dead!"
            return :game_over
        end
    end

    def living_players
        @players.select{|p| not p.is_dead? }
    end
    def run_rapids
        living_players.each do |player|
            player.run_rapids(@river)
            @provisions += player.take_action(@river, @jungle)
            player.take_illness
        end
    end

    def still_water_turn()
        current_player = @players[@turn % 3]
        @provisions += current_player.take_action(@river, @jungle)
        living_players.each{ |p| p.take_illness}
    end

    def to_s
        "LastTurn: #{@turn}\n\tProvisions: #{@provisions}\n\tCards:\n\t\tJungle #{@jungle}\n\t\tRiver #{@river}\n\tPlayers:\n\t\t#{@players.map {|p| p.to_s}.join("\n\t\t")}"
    end
end


results = Hash.new(0)
10000.times do
    game = Game.new
    15.times do |i|
        if game.turn() == :game_over
            results[i+1]+=1
            break
        end
        results[16] += 1 if i == 14
    end
    #puts game
end

puts results.keys.sort.map {|k| "#{k}: #{"*"*(results[k]/100)} #{results[k] / 10000.0}" }.join "\n"
