defmodule FrobotsScenic.Scene.Game do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Components

  import Scenic.Primitives,
    only: [rect: 3, text: 3, circle: 3, line: 3, arc: 3, add_specs_to_graph: 3]

  # Constants
  @name __MODULE__
  @font_size 20
  @font_vert_space @font_size + 2
  @tank_size 10
  # @tank_radius 2
  @miss_size 2
  @frame_ms 30
  # @boom_width 40
  # @boom_height 40
  @boom_radius 20

  @animate_ms 100
  @finish_delay_ms 5000

  @scan_radius 700

  # dummy match template (as the beta this stuff doesn't exist)
  @dummy_match_template %{
    entry_fee: 100,
    commission_rate: 10,
    match_type: :individual,
    # winner take all
    payout_map: [100],
    max_frobots: 4,
    min_frobots: 2
  }

  # types

  @type location :: {integer, integer}
  @type miss_name :: charlist()
  @type tank_name :: charlist()
  @type tank_status :: :alive | :destroyed
  @type miss_status :: :flying | :exploded
  @type object_map :: %{
          tank: %{charlist() => %FrobotsScenic.Scene.Game.Tank{}},
          missile: %{charlist() => %FrobotsScenic.Scene.Game.Missile{}}
        }
  @type t :: %{
          viewport: pid,
          tile_width: integer,
          tile_height: integer,
          graph: Scenic.Graph.t(),
          frame_count: integer,
          frame_timer: reference,
          score: integer,
          frobots: map,
          objects: object_map
        }

  defmodule Tank do
    @type npc_class :: :proto | :target

    @type t :: %{
            scan: {integer, integer},
            damage: integer,
            speed: integer,
            heading: integer,
            ploc: FrobotsScenic.Scene.Game.location(),
            loc: FrobotsScenic.Scene.Game.location(),
            id: integer,
            name: charlist(),
            timer: reference,
            status: FrobotsScenic.Scene.Game.tank_status(),
            fsm_state: charlist(),
            fsm_debug: charlist(),
            class: npc_class
          }
    defstruct scan: {0, 0},
              damage: 0,
              speed: 0,
              heading: 0,
              ploc: {0, 0},
              loc: {0, 0},
              id: nil,
              name: nil,
              timer: nil,
              status: :alive,
              fsm_state: nil,
              fsm_debug: nil,
              class: nil
  end

  defmodule Missile do
    @type t :: %{
            ploc: FrobotsScenic.Scene.Game.location(),
            loc: FrobotsScenic.Scene.Game.location(),
            status: FrobotsScenic.Scene.Game.miss_status(),
            name: charlist()
          }
    defstruct ploc: {0, 0},
              loc: {0, 0},
              name: nil,
              timer: nil,
              status: :flying
  end

  def header() do
    [
      button_spec("Cancel", id: :btn_cancel, theme: :primary, t: {400, 0})
    ]
  end

  def add_specs(graph) do
    add_specs_to_graph(
      graph,
      [
        header()
      ],
      translate: {500, 20}
    )
  end

  @blue_heads [:blue1, :blue2, :blue3, :blue4, :blue5, :blue6, :blue7, :blue8, :blue9]
  @red_heads [:red1, :red2, :red3, :red4, :red5, :red6, :red7]
  @yellow_heads [:yellow1, :yellow2]
  @rabbit_heads [:rabbit]
  @heads @blue_heads ++ @red_heads ++ @yellow_heads ++ @rabbit_heads

  # Initialize the game scene
  def init(frobots, opts) do
    viewport = opts[:viewport]

    Enum.map(@heads, fn head ->
      path = Map.get(Application.get_env(:frobots_scenic, :image_path), head)
      hash = Scenic.Cache.Support.Hash.file!(path, :sha)
      Scenic.Cache.Static.Texture.load!(path, hash)
    end)

    # calculate the transform that centers the viewport
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    # load the explode texture into the cache
    # Scenic.Cache.Static.Texture.load(@boom_path, @boom_hash)

    # start a very simple animation timer
    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    IO.puts("Registering pid #{inspect(self())} as display")
    :global.register_name(Application.get_env(:frobots, :display_process_name), self())

    graph =
      Graph.build(font: :roboto, font_size: 24, theme: :dark)
      |> add_specs()

    # init the game state
    # The entire game state will be held here
    # the frobots come in as arg from the start scene
    state = %{
      viewport: viewport,
      tile_width: vp_width,
      tile_height: vp_height,
      graph: graph,
      frame_count: 1,
      frame_timer: timer,
      frobots: frobots,
      objects: %{tank: %{}, missile: %{}}
    }

    case Frobots.start_fubars(Map.put(@dummy_match_template, :frobots, state.frobots)) do
      {:ok, frobots_map} ->
        state = init_frobot_states(state, frobots_map)

        # update the graph and push it to the rendered
        graph =
          state.graph
          |> draw_status(state.objects)
          |> draw_game_objects(state.objects)

        {:ok, state, push: graph}

      {:error, _error} ->
        # todo should probably show an error to the graph, as the game failed to start somehow.
        {:ok, state, push: state.graph}
    end
  end

  def filter_event({:click, :btn_cancel}, _, state) do
    {:ok, _} = :timer.cancel(state.frame_timer)
    Frobots.cancel_match()
    Process.send_after(self(), :restart, 1000)
    {:halt, state, push: state.graph}
  end

  defp keys_to_atoms(string_key_map) do
    for {key, val} <- string_key_map, into: %{}, do: {String.to_atom(key), val}
  end

  defp init_frobot_states(state, frobots_map) do
    Enum.reduce(frobots_map, state, fn [name, object_data], state ->
      put_in(
        state,
        [:objects, :tank, name],
        struct!(FrobotsScenic.Scene.Game.Tank, keys_to_atoms(IO.inspect(object_data)))
      )
    end)
  end

  defp draw_status(graph, object_map) do
    Enum.reduce(object_map, graph, fn
      {:tank, object_data}, graph ->
        if Enum.any?(object_data) do
          Enum.reduce(object_data, graph, fn {_name, object_struct}, graph ->
            draw_score(graph, object_struct)
          end)
        else
          graph
        end

      {_, _}, graph ->
        graph
    end)
  end

  defp alive?(damage) do
    cond do
      damage >= 100 -> false
      true -> true
    end
  end

  defp status_color(damage) do
    cond do
      alive?(damage) -> :grey
      true -> :dark_red
    end
  end

  defp damage_color(damage) do
    cond do
      damage > 80 -> :red
      damage > 60 -> :orange
      damage > 40 -> :dark_orange
      damage > 20 -> :dark_golden_rod
      true -> :green
    end
  end

  # https://htmlcolorcodes.com/color-names/
  # https://hexdocs.pm/scenic/Scenic.Primitive.Style.Paint.Color.html#module-valid-colors
  defp tank_icon(class, name) do
    head =
      if String.match?(name, ~r/rabbit/i) do
        Enum.random(@rabbit_heads)
      else
        get_head(class)
      end

    path = Map.get(Application.get_env(:frobots_scenic, :image_path), head)
    hash = Scenic.Cache.Support.Hash.file!(path, :sha)
    {:image, hash}
  end

  defp get_head(class) do
    cond do
      class == Frobots.prototype_class() -> Enum.random(@red_heads)
      class == Frobots.target_class() -> Enum.random(@yellow_heads)
      true -> Enum.random(@blue_heads)
    end
  end

  # Draw the game grid
  defp draw_grid(graph) do
    range = for n <- 0..1000, rem(n, 10) == 0, do: n
    draw_horiz = fn y, graph -> line(graph, {{0, y}, {1000, y}}, stroke: {1, :dark_blue}) end
    draw_vert = fn x, graph -> line(graph, {{x, 0}, {x, 1000}}, stroke: {1, :dark_blue}) end

    draw_horizontals = fn graph ->
      Enum.reduce(range, graph, fn n, graph -> draw_horiz.(n, graph) end)
    end

    draw_verticals = fn graph ->
      Enum.reduce(range, graph, fn n, graph -> draw_vert.(n, graph) end)
    end

    graph
    |> draw_horizontals.()
    |> draw_verticals.()
  end

  # Draw the score HUD
  defp draw_score(graph, %@name.Tank{
         name: name,
         id: id,
         scan: {deg, res},
         damage: damage,
         heading: heading,
         speed: speed,
         fsm_state: fsm_state,
         fsm_debug: fsm_debug
       }) do
    graph
    |> text("#{name}",
      id: name,
      fill: status_color(damage),
      translate: {10, 10 + id * @font_vert_space}
    )
    |> text("dm:#{damage}",
      fill: damage_color(damage),
      translate: {150, 10 + id * @font_vert_space}
    )
    |> text("sp:#{trunc(speed)}",
      fill: status_color(damage),
      translate: {220, 10 + id * @font_vert_space}
    )
    |> text("hd:#{heading}",
      fill: status_color(damage),
      translate: {290, 10 + id * @font_vert_space}
    )
    |> text("sc:#{deg}:#{res}",
      fill: status_color(damage),
      translate: {360, 10 + id * @font_vert_space}
    )
    |> text("st:#{fsm_state}",
      fill: status_color(damage),
      translate: {450, 10 + id * @font_vert_space}
    )
    |> text("debug:#{fsm_debug}",
      fill: status_color(damage),
      translate: {570, 10 + id * @font_vert_space}
    )
  end

  defp draw_game_over(graph, name, vp_width, vp_height) do
    position = {
      vp_width / 2 - String.length(name) * @font_size / 2,
      vp_height / 2 - @font_vert_space / 2
    }

    graph |> text("Winner: #{name}!", font_size: 32, fill: :yellow, translate: position)
  end

  # iterates over the object map, rendering each object.
  defp draw_game_objects(graph, object_map) do
    Enum.reduce(object_map, graph, fn {object_type, object_data}, graph ->
      if Enum.any?(object_data) do
        Enum.reduce(object_data, graph, fn {_name, object_struct}, graph ->
          draw_object(graph, object_type, object_struct)
        end)
      else
        graph
      end
    end)
  end

  # draw tanks
  defp draw_object(graph, :tank, %@name.Tank{loc: {x, y}, name: name, status: status})
       when status in [:destroyed] do
    draw_tank_destroy(graph, x, y, name, id: name)
  end

  defp draw_object(graph, :tank, %@name.Tank{loc: {x, y}, name: name, id: id, class: class}) do
    draw_tank(graph, x, y, id, fill: tank_icon(class, name), id: name)
  end

  # draw missiles
  defp draw_object(graph, :missile, %@name.Missile{loc: {x, y}, name: name, status: status})
       when status in [:exploded] do
    # draw_miss_explode(graph, x, y, name, id: name, fill: {:image, {@boom_hash, 256}} )
    draw_miss_explode(graph, x, y, name, id: name, fill: :orange)
  end

  defp draw_object(graph, :missile, %@name.Missile{loc: {x, y}, name: name}) do
    draw_missile(graph, x, y, fill: :yellow, id: name)
  end

  defp draw_object(graph, :missile, nil) do
    graph
  end

  # draw tanks as rounded rectangles
  defp draw_tank(graph, x, y, _id, opts) do
    tile_opts =
      Keyword.merge(opts,
        translate: {x - @tank_size / 2, y - @tank_size / 2}
      )

    graph
    |> rect({@tank_size, @tank_size}, tile_opts)
  end

  # draw missiles as circles
  defp draw_missile(graph, x, y, opts) do
    tile_opts = Keyword.merge([translate: {x, y}], opts)
    graph |> circle(@miss_size, tile_opts)
  end

  defp draw_tank_destroy(graph, _x, _y, name, _opts) do
    graph |> Graph.delete(name)
  end

  defp draw_miss_explode(graph, x, y, m_name, opts) do
    tile_opts = Keyword.merge([translate: {x, y}], opts)
    # delete the old primitive
    graph
    |> Graph.delete(m_name)
    |> circle(@boom_radius, tile_opts)
  end

  defp update_loc(object_data, loc) do
    if object_data do
      object_data |> Map.put(:ploc, Map.get(object_data, loc)) |> Map.put(:loc, loc)
    end
  end

  defp update_status(object_data, status) do
    object_data |> Map.put(:status, status)
  end

  defp update_timer(object_data, timer) do
    object_data |> Map.put(:timer, timer)
  end

  # defp update_alpha(object_data, alpha) do
  #   object_data |> Map.put(:alpha, alpha)
  # end

  defp update_damage(object_data, damage) do
    object_data |> Map.put(:damage, damage)
  end

  defp update_scan(object_data, deg, res) do
    object_data |> Map.put(:scan, {deg, res})
  end

  defp update_heading_speed(object_data, heading, speed) do
    object_data |> Map.put(:speed, speed) |> Map.put(:heading, heading)
  end

  defp update_fsm_state(object_data, fsm_state) do
    object_data |> Map.put(:fsm_state, fsm_state)
  end

  defp update_fsm_debug(object_data, fsm_debug) do
    object_data |> Map.put(:fsm_debug, fsm_debug)
  end

  defp update_in?(map, path, func) do
    if get_in(map, path) do
      update_in(map, path, func)
    else
      map
    end
  end

  defp draw_scan(graph, loc, deg, res) do
    {x, y} = loc

    x2 = x + @scan_radius * :math.cos(:math.pi() * (deg - res) / 180)
    y2 = y + @scan_radius * :math.sin(:math.pi() * (deg - res) / 180)

    x3 = x + @scan_radius * :math.cos(:math.pi() * (deg + res) / 180)
    y3 = y + @scan_radius * :math.sin(:math.pi() * (deg + res) / 180)

    graph
    |> line({loc, {x2, y2}}, stroke: {1, :yellow}, cap: :round)
    |> line({loc, {x3, y3}}, stroke: {1, :yellow}, cap: :round)
    |> arc({@scan_radius, :math.pi() * (deg - res) / 180, :math.pi() * (deg + res) / 180},
      fill: :yellow,
      stroke: {1, :yellow},
      t: loc
    )
  end

  @spec handle_info({:fsm_debug, tank_name, charlist}, t) :: tuple
  def handle_info({:fsm_debug, frobot, fsm_debug}, state) do
    state = update_in?(state, [:objects, :tank, frobot], &update_fsm_debug(&1, fsm_debug))
    {:noreply, state}
  end

  @spec handle_info({:fsm_state, tank_name, charlist}, t) :: tuple
  def handle_info({:fsm_state, frobot, fsm_state}, state) do
    state = update_in?(state, [:objects, :tank, frobot], &update_fsm_state(&1, fsm_state))
    {:noreply, state}
  end

  @spec handle_info({:scan, tank_name, integer, integer}, t) :: tuple
  def handle_info({:scan, frobot, deg, res}, state) do
    state = update_in?(state, [:objects, :tank, frobot], &update_scan(&1, deg, res))

    graph =
      state.graph
      |> draw_grid()
      |> draw_game_objects(state.objects)
      |> draw_status(state.objects)
      |> draw_scan(state.objects.tank |> Map.get(frobot) |> Map.get(:loc), deg, res)

    {:noreply, state, push: graph}
  end

  @spec handle_info({:damage, tank_name, integer}, t) :: tuple
  def handle_info({:damage, frobot, damage}, state) do
    state = update_in?(state, [:objects, :tank, frobot], &update_damage(&1, damage))
    {:noreply, state}
  end

  @spec handle_info({:create_tank, tank_name, tuple}, t) :: tuple
  def handle_info({:create_tank, frobot, loc}, state) do
    # nop because tanks are created by the init, and we can ignore this message
    # may use this if in future init does not place the tank at loc, and only gives it a name and id.
    state = update_in?(state, [:objects, :tank, frobot], &update_loc(&1, loc))
    {:noreply, state}
  end

  @spec handle_info({:move_tank, tank_name, tuple, integer, integer}, t) :: tuple
  def handle_info({:move_tank, frobot, loc, heading, speed}, state) do
    state =
      state
      |> update_in?([:objects, :tank, frobot], &update_loc(&1, loc))
      |> update_in?([:objects, :tank, frobot], &update_heading_speed(&1, heading, speed))

    {:noreply, state}
  end

  @spec handle_info({:kill_tank, tank_name}, t) :: tuple
  def handle_info({:kill_tank, frobot}, state) do
    state = update_in?(state, [:objects, :tank, frobot], &update_status(&1, :destroyed))
    {:noreply, state}
  end

  @spec handle_info({:create_miss, miss_name, tuple}, t) :: tuple
  def handle_info({:create_miss, m_name, loc}, state) do
    state = put_in(state, [:objects, :missile, m_name], %@name.Missile{name: m_name, loc: loc})

    {:noreply, state}
  end

  @spec handle_info({:move_miss, miss_name, tuple}, t) :: tuple
  def handle_info({:move_miss, m_name, loc}, state) do
    state = update_in?(state, [:objects, :missile, m_name], &update_loc(&1, loc))
    {:noreply, state}
  end

  @spec handle_info({:kill_miss, miss_name}, t) :: tuple
  def handle_info({:kill_miss, m_name}, state) do
    # start a very simple animation timer
    {:ok, timer} = :timer.send_after(@animate_ms, {:remove, m_name, :missile})
    if timer == nil, do: raise(RuntimeError)

    state =
      state
      |> update_in?([:objects, :missile, m_name], &update_status(&1, :exploded))
      |> update_in?([:objects, :missile, m_name], &update_timer(&1, timer))

    {:noreply, state}
  end

  # this will remove the object both tanks and missiles
  def handle_info({:remove, name, :missile}, state) do
    state = state |> put_in([:objects, :missile], Map.delete(state.objects.missile, name))
    {:noreply, state}
  end

  def handle_info({:remove, name, :tank}, state) do
    state = state |> put_in([:objects, :tank], Map.delete(state.objects.tank, name))
    {:noreply, state}
  end

  # this is the refresh loop of the display
  def handle_info(:frame, %{frame_count: frame_count} = state) do
    graph =
      state.graph |> draw_grid() |> draw_game_objects(state.objects) |> draw_status(state.objects)

    {:noreply, %{state | frame_count: frame_count + 1}, push: graph}
  end

  def handle_info({:game_over, names}, state) do
    IO.inspect(names = Tuple.to_list(names))
    {:ok, _} = :timer.cancel(state.frame_timer)
    graph = state.graph |> draw_game_over(~s/#{names}/, state.tile_width, state.tile_height)
    Process.send_after(self(), :restart, @finish_delay_ms)
    {:noreply, state, push: graph}
  end

  def handle_info(:restart, state) do
    FrobotsScenic.Scene.Landing.go_to_start_scene(%{
      viewport: state.viewport,
      module: FrobotsScenic.Scene.Start
    })

    {:noreply, state, push: state.graph}
  end

  # keyboard controls (currently no controls)
  def handle_input(_input, _context, state), do: {:noreply, state}
end
