## State

Các thuộc tính cơ bản của contract

| StateName        | Description                                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------------- |
| isInit           | Boolean dùng để check hàm chỉ gọi một lần                                                               |
| REAL             | Address token ERC20                                                                                     |
| TGE_RELEASE      | Thời gian lock                                                                                          |
| VESTING_DURATION | Tổng thời gian invest                                                                                   |
| REAL_PRICE       | Giá bán                                                                                                 |
| TOTAL_ALLOCATION | Tổng số lượng bán                                                                                       |
| startTime        | Thời gian bắt đầu cho user claim invest ( time set + TGE_RELEASE ) ( Không tính thời gian release TGE ) |
| endTime          | Thời gian kết thúc ( startTime + VESTING_DURATION )                                                     |
| stage            | Stage 0 = Init, Stage 1 = Start                                                                         |
| whilelists       | List address user tham gia mua - set là whitelist                                                       |
| locks            | Tổng số lượng token lock khi user tham gia mua ( Tính theo mỗi address user )                           |
| released         | Tổng token user có thể claim invest sau startTime                                                       |

## Bước 1: Sử dụng hàm initial(ERC20 real) {}

- real: Address token REAL.

## Bước 2: Set user whitelist - sử dụng hàm setWhilelist(address[] calldata users, uint256[] calldata balance) {}

- users: Array address user tham gia.
- balance: Array balance của user tham gia.
- Length của array users và balance phải bằng nhau.

vd: [addressUser1, addressUser2, addressUser3] - [1000000000000000000000 (Số lượng USDT * decimals user1 mua - 1000 USDT), 2000000000000000000000, 3000000000000000000000]

- Mỗi index trong array users và balance phải match với nhau

## Bước 2: Set tgian claim và trả TGE - setTime(uint256 time) {}

- Function dùng để trả TGE cho user ngay lập tức, và tính thời gian claim invest.
- Đối với Team và Advisor sẽ không có trả TGE.

- time: Thời gian hiện tại.

- startTime = time + TGE_RELEASE
- endTime = startTime + VESTING_DURATION
