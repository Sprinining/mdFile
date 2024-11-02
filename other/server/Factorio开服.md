## Factorio开服

- [官方教程](https://wiki.factorio.com/Multiplayer/zh#%E4%B8%93%E7%94%A8/Headless%E6%9C%8D%E5%8A%A1%E5%99%A8)

### 配置文件

#### map-gen-settings.example.json

设置地图生成的参数。该文件定义了地图生成时的一些特性和规则，允许玩家自定义地图的结构和资源分布。

```json
{
  // 地图的宽度和高度，以块为单位；0表示无限
  "_comment_width+height": "Width and height of map, in tiles; 0 means infinite",
  "width": 0,
  "height": 0,

  // 'biter free zone radius' 的倍数
  "_starting_area_comment": "Multiplier for 'biter free zone radius'",
  "starting_area": 1,

  // 是否开启和平模式
  "peaceful_mode": false,

  // 资源的自定义生成设置
  "autoplace_controls":
  {
    // 煤矿的生成频率、大小和丰富度
    "coal": {"frequency": 1, "size": 1, "richness": 1},
    // 石头的生成频率、大小和丰富度
    "stone": {"frequency": 1, "size": 1, "richness": 1},
    // 铜矿的生成频率、大小和丰富度
    "copper-ore": {"frequency": 1, "size": 1,"richness": 1},
    // 铁矿的生成频率、大小和丰富度
    "iron-ore": {"frequency": 1, "size": 1, "richness": 1},
    // 铀矿的生成频率、大小和丰富度
    "uranium-ore": {"frequency": 1, "size": 1, "richness": 1},
    // 原油的生成频率、大小和丰富度
    "crude-oil": {"frequency": 1, "size": 1, "richness": 1},
    // 水的生成频率和大小
    "water": {"frequency": 1, "size": 1},
    // 树木的生成频率和大小
    "trees": {"frequency": 1, "size": 1},
    // 敌对基地的生成频率和大小
    "enemy-base": {"frequency": 1, "size": 1}
  },

  // 悬崖的生成设置
  "cliff_settings":
  {
    // 悬崖原型的名称
    "_name_comment": "Name of the cliff prototype",
    "name": "cliff",

    // 第一行悬崖的高度
    "_cliff_elevation_0_comment": "Elevation of first row of cliffs",
    "cliff_elevation_0": 10,

    // 连续悬崖的高度差
    "_cliff_elevation_interval_comment":
    [
      "Elevation difference between successive rows of cliffs.",
      "This is inversely proportional to 'frequency' in the map generation GUI. Specifically, when set from the GUI the value is 40 / frequency."
    ],
    "cliff_elevation_interval": 40,

    // 悬崖的丰富度
    "_richness_comment": "Called 'cliff continuity' in the map generator GUI. 0 will result in no cliffs, 10 will make all cliff rows completely solid",
    "richness": 1
  },

  // 属性值生成器的覆盖设置（地图类型）
  "_property_expression_names_comment":
  [
    "Overrides for property value generators (map type)",
    "Leave 'elevation' blank to get 'normal' terrain.",
    "Use 'elevation': 'elevation_island' to get an island.",
    "Moisture and terrain type are also controlled via this.",
    "'control:moisture:frequency' is the inverse of the 'moisture scale' in the map generator GUI.",
    "'control:moisture:bias' is the 'moisture bias' in the map generator GUI.",
    "'control:aux:frequency' is the inverse of the 'terrain type scale' in the map generator GUI.",
    "'control:aux:bias' is the 'terrain type bias' in the map generator GUI."
  ],
  "property_expression_names":
  {
    // 湿度频率控制
    "control:moisture:frequency": "1",
    // 湿度偏置
    "control:moisture:bias": "0",
    // 地形类型频率控制
    "control:aux:frequency": "1",
    // 地形类型偏置
    "control:aux:bias": "0"
  },

  // 起始点设置
  "starting_points":
  [
    // 起始点的坐标
    { "x": 0, "y": 0}
  ],

  // 使用 null 表示随机种子，数字表示特定种子
  "_seed_comment": "Use null for a random seed, number for a specific seed.",
  "seed": null
}
```

#### map-settings.example.json

用于设置游戏地图的生成和特性。玩家可以根据自己的需求修改此文件，以定制新创建地图的具体设置。

```json
{
  // 游戏难度设置
  "difficulty_settings":
  {
    // 技术价格的倍增因子
    "technology_price_multiplier": 1,
    // 溶解时间的修改因子
    "spoil_time_modifier" : 1
  },
  
  // 污染相关设置
  "pollution":
  {
    // 是否启用污染
    "enabled": true,
    // 以下是60个ticks（1个模拟秒）的值
    "_comment_min_to_diffuse_1": "these are values for 60 ticks (1 simulated second)",
    // 扩散到相邻区块的污染量
    "_comment_min_to_diffuse_2": "amount that is diffused to neighboring chunk",
    // 扩散比率
    "diffusion_ratio": 0.02,
    // 扩散所需的最小污染值
    "min_to_diffuse": 15,
    // 污染的衰老因子
    "ageing": 1,
    // 每个区块的预期最大污染量
    "expected_max_per_chunk": 150,
    // 每个区块的最小显示污染量
    "min_to_show_per_chunk": 50,
    // 造成树木损坏的最小污染量
    "min_pollution_to_damage_trees": 60,
    // 造成最大森林损坏的污染量
    "pollution_with_max_forest_damage": 150,
    // 每棵树造成的污染量
    "pollution_per_tree_damage": 50,
    // 每棵树恢复的污染量
    "pollution_restored_per_tree_damage": 10,
    // 最大恢复树木的污染量
    "max_pollution_to_restore_trees": 20,
    // 敌人攻击时的污染消耗修改因子
    "enemy_attack_pollution_consumption_modifier": 1
  },

  // 敌人进化相关设置
  "enemy_evolution":
  {
    // 是否启用敌人进化
    "enabled": true,
    // 时间因子
    "time_factor": 0.000004,
    // 毁坏因子
    "destroy_factor": 0.002,
    // 污染因子
    "pollution_factor": 0.0000009
  },

  // 敌人扩张相关设置
  "enemy_expansion":
  {
    // 是否启用敌人扩张
    "enabled": true,
    // 最大扩张距离
    "max_expansion_distance": 7,
    // 友方基地影响半径
    "friendly_base_influence_radius": 2,
    // 敌方建筑影响半径
    "enemy_building_influence_radius": 2,
    // 建筑系数
    "building_coefficient": 0.1,
    // 其他基地系数
    "other_base_coefficient": 2.0,
    // 邻近区块系数
    "neighbouring_chunk_coefficient": 0.5,
    // 邻近基地区块系数
    "neighbouring_base_chunk_coefficient": 0.4,
    // 最大重叠瓷砖系数
    "max_colliding_tiles_coefficient": 0.9,
    // 定居者最小组大小
    "settler_group_min_size": 5,
    // 定居者最大组大小
    "settler_group_max_size": 20,
    // 最小扩张冷却时间（以ticks为单位）
    "min_expansion_cooldown": 14400,
    // 最大扩张冷却时间（以ticks为单位）
    "max_expansion_cooldown": 216000
  },

  // 单位组相关设置
  "unit_group":
  {
    // 最小组集合时间（以ticks为单位）
    "min_group_gathering_time": 3600,
    // 最大组集合时间（以ticks为单位）
    "max_group_gathering_time": 36000,
    // 最大等待时间（以ticks为单位）
    "max_wait_time_for_late_members": 7200,
    // 最大组半径
    "max_group_radius": 30.0,
    // 最小组半径
    "min_group_radius": 5.0,
    // 当落后成员加速的最大倍数
    "max_member_speedup_when_behind": 1.4,
    // 当前方成员减速的最大倍数
    "max_member_slowdown_when_ahead": 0.6,
    // 最大组减速因子
    "max_group_slowdown_factor": 0.3,
    // 最大组成员后退因子
    "max_group_member_fallback_factor": 3,
    // 成员被抛弃的距离
    "member_disown_distance": 10,
    // 成员到达时的tick容忍度
    "tick_tolerance_when_member_arrives": 60,
    // 最大集合单位组数
    "max_gathering_unit_groups": 30,
    // 最大单位组大小
    "max_unit_group_size": 200
  },

  // 驾驶相关设置
  "steering":
  {
    // 默认设置
    "default":
    {
      // 半径
      "radius": 1.2,
      // 分离力
      "separation_force": 0.005,
      // 分离因子
      "separation_factor": 1.2,
      // 是否强制单位模糊前往行为
      "force_unit_fuzzy_goto_behavior": false
    },
    // 移动设置
    "moving":
    {
      // 半径
      "radius": 3,
      // 分离力
      "separation_force": 0.01,
      // 分离因子
      "separation_factor": 3,
      // 是否强制单位模糊前往行为
      "force_unit_fuzzy_goto_behavior": false
    }
  },

  // 路径查找相关设置
  "path_finder":
  {
    // 前进与后退的比例
    "fwd2bwd_ratio": 5,
    // 目标压力比例
    "goal_pressure_ratio": 2,
    // 每个tick最大工作步骤
    "max_steps_worked_per_tick": 1000,
    // 每个tick最大完成工作量
    "max_work_done_per_tick": 8000,
    // 是否使用路径缓存
    "use_path_cache": true,
    // 短缓存大小
    "short_cache_size": 5,
    // 长缓存大小
    "long_cache_size": 25,
    // 短缓存最小可缓存距离
    "short_cache_min_cacheable_distance": 10,
    // 短缓存最小算法步骤数
    "short_cache_min_algo_steps_to_cache": 50,
    // 长缓存最小可缓存距离
    "long_cache_min_cacheable_distance": 30,
    // 缓存最大连接步骤乘数
    "cache_max_connect_to_cache_steps_multiplier": 100,
    // 缓存接受路径开始距离比率
    "cache_accept_path_start_distance_ratio": 0.2,
    // 缓存接受路径结束距离比率
    "cache_accept_path_end_distance_ratio": 0.15,
    // 负缓存接受路径开始距离比率
    "negative_cache_accept_path_start_distance_ratio": 0.3,
    // 负缓存接受路径结束距离比率
    "negative_cache_accept_path_end_distance_ratio": 0.3,
    // 缓存路径开始距离评级乘数
    "cache_path_start_distance_rating_multiplier": 10,
    // 缓存路径结束距离评级乘数
    "cache_path_end_distance_rating_multiplier": 20,
    // 相同目标的过时敌人碰撞惩罚
    "stale_enemy_with_same_destination_collision_penalty": 30,
    // 忽略移动敌人碰撞的距离
    "ignore_moving_enemy_collision_distance": 5,
    // 不同目标的敌人碰撞惩罚
    "enemy_with_different_destination_collision_penalty": 30,
    // 一般实体碰撞惩罚
    "general_entity_collision_penalty": 10,
    // 一般实体后续碰撞惩罚
    "general_entity_subsequent_collision_penalty": 3,
    // 扩展碰撞惩罚
    "extended_collision_penalty": 3,
    // 最大接受任何新请求的客户端数
    "max_clients_to_accept_any_new_request": 10,
    // 最大接受短请求的客户端数
    "max_clients_to_accept_short_new_request": 100,
    // 考虑短请求的直接距离
    "direct_distance_to_consider_short_request": 100,
    // 短请求最大步骤
    "short_request_max_steps": 1000,
    // 短请求比例
    "short_request_ratio": 0.5,
    // 检查路径查找终止的最小步骤
    "min_steps_to_check_path_find_termination": 2000,
    // 从开始到目标的成本乘数以终止路径查找
    "start_to_goal_cost_multiplier_to_terminate_path_find": 2000.0,
    // 超载级别
    "overload_levels": [0, 100, 500],
    // 超载乘数
    "overload_multipliers": [2, 3, 4],
    // 负路径缓存延迟间隔
    "negative_path_cache_delay_interval": 20
  },

  // 小行星相关设置
  "asteroids":
  {
    // 生成速率
    "spawning_rate" : 1,
    // 每个tick最大扩展的光线传送门数
    "max_ray_portals_expanded_per_tick" : 100
  },

  // 最大失败行为计数
  "max_failed_behavior_count": 3
}
```

#### server-settings.example.json

包含了一些服务器的设置选项，玩家可以根据自己的需求进行调整，以便定制服务器的行为和特性。

```json
{
  // 游戏名称，将在游戏列表中显示
  "name": "Name of the game as it will appear in the game listing",
  
  // 游戏描述，将在游戏列表中显示
  "description": "Description of the game that will appear in the listing",
  
  // 游戏标签，用于分类和搜索
  "tags": [ "game", "tags" ],

  // 最大玩家数量设置
  "_comment_max_players": "Maximum number of players allowed, admins can join even a full server. 0 means unlimited.",
  "max_players": 0,

  // 游戏可见性设置
  "_comment_visibility": [
    "public: Game will be published on the official Factorio matching server",
    "lan: Game will be broadcast on LAN"
  ],
  "visibility": {
    "public": true, // 是否在官方匹配服务器上发布
    "lan": true // 是否在局域网广播
  },

  // 登录凭据，用于公共可见性游戏
  "_comment_credentials": "Your factorio.com login credentials. Required for games with visibility public",
  "username": "", // Factorio.com 用户名
  "password": "", // Factorio.com 密码

  // 认证令牌，可以代替上面的密码
  "_comment_token": "Authentication token. May be used instead of 'password' above.",
  "token": "",

  // 游戏密码
  "game_password": "",

  // 用户验证设置，确保只有拥有有效账号的玩家可以连接
  "_comment_require_user_verification": "When set to true, the server will only allow clients that have a valid Factorio.com account",
  "require_user_verification": true,

  // 最大上传带宽设置，单位为千字节每秒，0 表示无限制
  "_comment_max_upload_in_kilobytes_per_second": "optional, default value is 0. 0 means unlimited.",
  "max_upload_in_kilobytes_per_second": 0,

  // 最大上传插槽数量，0 表示无限制
  "_comment_max_upload_slots": "optional, default value is 5. 0 means unlimited.",
  "max_upload_slots": 5,

  // 最小延迟设置（以 ticks 为单位），一个 tick 默认是 16 毫秒，0 表示没有最小延迟
  "_comment_minimum_latency_in_ticks": "optional one tick is 16ms in default speed, default value is 0. 0 means no minimum.",
  "minimum_latency_in_ticks": 0,

  // 网络心跳每秒的最大数量，游戏数据包发送的最大频率
  "_comment_max_heartbeats_per_second": "Network tick rate. Maximum rate game updates packets are sent at before bundling them together. Minimum value is 6, maximum value is 240.",
  "max_heartbeats_per_second": 60,

  // 允许返回玩家在达到最大玩家数量后仍然可以加入
  "_comment_ignore_player_limit_for_returning_players": "Players that played on this map already can join even when the max player limit was reached.",
  "ignore_player_limit_for_returning_players": false,

  // 命令设置，允许执行的命令类型
  "_comment_allow_commands": "possible values are, true, false and admins-only",
  "allow_commands": "admins-only",

  // 自动保存间隔，以分钟为单位
  "_comment_autosave_interval": "Autosave interval in minutes",
  "autosave_interval": 10,

  // 服务器自动保存的插槽数量，保存时轮换使用
  "_comment_autosave_slots": "server autosave slots, it is cycled through when the server autosaves.",
  "autosave_slots": 5,

  // 自动踢掉长时间无操作玩家的间隔，以分钟为单位，0 表示永不踢出
  "_comment_afk_autokick_interval": "How many minutes until someone is kicked when doing nothing, 0 for never.",
  "afk_autokick_interval": 0,

  // 是否在没有玩家时暂停服务器
  "_comment_auto_pause": "Whether should the server be paused when no players are present.",
  "auto_pause": true,

  // 是否在玩家连接时暂停服务器
  "_comment_auto_pause_when_players_connect": "Whether should the server be paused when someone is connecting to the server.",
  "auto_pause_when_players_connect": false,

  // 仅管理员可以暂停游戏
  "only_admins_can_pause_the_game": true,

  // 自动保存是否仅在服务器上保存，默认是true
  "_comment_autosave_only_on_server": "Whether autosaves should be saved only on server or also on all connected clients. Default is true.",
  "autosave_only_on_server": true,

  // 非阻塞保存，实验性功能，启用需谨慎
  "_comment_non_blocking_saving": "Highly experimental feature, enable only at your own risk of losing your saves. On UNIX systems, server will fork itself to create an autosave. Autosaving on connected Windows clients will be disabled regardless of autosave_only_on_server option.",
  "non_blocking_saving": false,

  // 网络消息分段设置，影响服务器和客户端的带宽需求
  "_comment_segment_sizes": "Long network messages are split into segments that are sent over multiple ticks. Their size depends on the number of peers currently connected. Increasing the segment size will increase upload bandwidth requirement for the server and download bandwidth requirement for clients. This setting only affects server outbound messages. Changing these settings can have a negative impact on connection stability for some clients.",
  "minimum_segment_size": 25, // 最小分段大小
  "minimum_segment_size_peer_count": 20, // 最小分段大小的对等数量
  "maximum_segment_size": 100, // 最大分段大小
  "maximum_segment_size_peer_count": 10 // 最大分段大小的对等数量
}
```

#### server-whitelist.example.json

用于设置 Factorio 服务器的白名单。白名单是一种安全机制，允许只有特定的玩家（通常通过他们的用户名或ID）连接到服务器，而其他玩家则被拒绝访问。

```json
[
  "Rseding91",
  "Oxyd"
]
```

上述四个文件需要新建，去掉 example

- 新建存档

```shell
./bin/x64/factorio --create saves/my-save.zip --map-gen-settings map-gen-settings.json --map-settings map-settings.json
```

- 修改 `factorio/mods/mod-list.json`，启动 mod

- 开启服务器

```shell
./bin/x64/factorio --start-server-load-latest --server-settings ./server-settings.json
```
