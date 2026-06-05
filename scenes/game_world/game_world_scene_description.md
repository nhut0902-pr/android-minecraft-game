# Mô tả Scene: `game_world.tscn`

Scene `game_world.tscn` sẽ là scene chính nơi gameplay diễn ra. Nó sẽ chứa người chơi, thế giới voxel được tạo ra, và các thành phần UI trong game.

## Cấu trúc cây Scene

```
Node3D (Root Node)
├── WorldEnvironment
│   └── DirectionalLight3D
├── ChunkManager (Node)
│   └── WorldGenerator (Node)
│   └── VoxelBlockSystem (Node)
├── Player (CharacterBody3D)
│   ├── Head (Node3D)
│   │   └── Camera3D
│   └── PlayerController (Script)
├── UI (CanvasLayer)
│   ├── Crosshair (Control)
│   ├── HotbarUI (Control)
│   ├── InventoryUI (Control)
│   └── DebugUI (Control)
└── NavigationRegion3D
```

## Mô tả các Node

*   **`Node3D` (Root Node):** Node gốc của scene game, dùng để chứa tất cả các đối tượng 3D khác.

*   **`WorldEnvironment`:**
    *   Chứa `Environment` resource để định nghĩa bầu trời, ánh sáng môi trường, sương mù, v.v.
    *   **`DirectionalLight3D`:** Ánh sáng mặt trời/mặt trăng, mô phỏng chu kỳ ngày đêm.

*   **`ChunkManager` (Node):**
    *   Node này sẽ là một instance của script `ChunkManager.gd`.
    *   Nó sẽ quản lý việc tạo, tải và dỡ các chunk voxel xung quanh người chơi.
    *   **`WorldGenerator` (Node):** Instance của script `WorldGenerator.gd`, chịu trách nhiệm tạo dữ liệu khối cho từng chunk.
    *   **`VoxelBlockSystem` (Node):** Instance của script `VoxelBlockSystem.gd`, chịu trách nhiệm tạo mesh 3D từ dữ liệu khối.

*   **`Player` (CharacterBody3D):**
    *   Node này sẽ là một instance của `PlayerController.gd`.
    *   Chứa `CollisionShape3D` để phát hiện va chạm.
    *   **`Head` (Node3D):** Node con của `Player`, dùng để xoay camera theo chiều dọc.
        *   **`Camera3D`:** Camera chính của người chơi, gắn vào `Head` để tạo góc nhìn thứ nhất.
    *   **`PlayerController.gd`:** Script điều khiển chuyển động, nhảy, tương tác (phá/đặt khối) của người chơi.

*   **`UI` (CanvasLayer):** Node gốc cho tất cả các thành phần giao diện người dùng (UI) trong game.
    *   **`Crosshair` (Control):** Dấu thập ở giữa màn hình để chỉ mục tiêu.
    *   **`HotbarUI` (Control):** Thanh công cụ nhanh hiển thị các vật phẩm đang được chọn.
    *   **`InventoryUI` (Control):** Giao diện kho đồ đầy đủ, chỉ hiển thị khi người chơi mở.
    *   **`DebugUI` (Control):** Hiển thị thông tin debug như FPS, tọa độ người chơi (chỉ dùng trong phát triển).

*   **`NavigationRegion3D`:** Dùng cho hệ thống tìm đường của AI (mob). Nó sẽ bao phủ khu vực thế giới để các mob có thể tính toán đường đi.

## Các bước tạo Scene trong Godot Editor

1.  Tạo một Scene 3D mới và lưu nó thành `game_world.tscn` trong thư mục `res://scenes/game_world/`.
2.  Đổi tên Node gốc thành `GameWorld`.
3.  Thêm các Node con như mô tả ở trên.
4.  Gắn các script tương ứng (`ChunkManager.gd`, `PlayerController.gd`, v.v.) vào các Node của chúng.
5.  Cấu hình `WorldEnvironment` và `DirectionalLight3D` để có ánh sáng và bầu trời cơ bản.
6.  Thiết lập `Camera3D` với các thông số phù hợp cho góc nhìn thứ nhất.
7.  Thiết kế các thành phần UI (`Crosshair`, `HotbarUI`, v.v.) bằng các Node Control của Godot và gắn các script UI tương ứng (sẽ được viết sau).
8.  Đảm bảo rằng `ChunkManager` và `Player` được khởi tạo và kết nối đúng cách. Ví dụ, `ChunkManager` cần nhận vị trí của người chơi để tải chunk.
