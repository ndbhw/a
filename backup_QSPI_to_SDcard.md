# Backup QSPI flash ra thẻ SD (U-Boot)

- Flash: W25Q128, 16 MiB (`0x1000000`), page 256 byte, erase sector 4 KiB.
- Thẻ SD phân vùng 2 (`mmc 0:2`), FAT32. Trong Linux phân vùng này mount tại `/run/media/mmcblk0p2`.
- File backup: `/Home/root/qspi_backup.bin` trên phân vùng 2.
- Vùng RAM dùng tạm: `0x08000000` (đọc từ flash), `0x09000000` (đọc lại để kiểm tra).

Tất cả lệnh chạy trong U-Boot.

## Bước 1: Nhận flash QSPI

```
sf probe 0 0 0
```

Kết quả đúng: `SF: Detected w25q128 with page size 256 Bytes, erase size 4 KiB, total 16 MiB`

## Bước 2: Nhận thẻ SD và xem phân vùng

```
mmc dev 0
mmc rescan
mmc info
mmc part
```

## Bước 3: Xem nội dung phân vùng 2

```
fatls mmc 0:2 /
```

## Bước 4: Tạo thư mục `/Home/root`

Bỏ qua nếu bước 3 đã thấy thư mục `Home/`.

```
fatmkdir mmc 0:2 /Home
fatmkdir mmc 0:2 /Home/root
fatls mmc 0:2 /Home
```

## Bước 5: Đọc toàn bộ 16 MiB flash vào RAM

```
sf read 0x08000000 0x0 0x1000000
```

Kết quả đúng: `SF: 16777216 bytes @ 0x0 Read: OK`

## Bước 6: Tính CRC của dữ liệu vừa đọc

Ghi lại kết quả.

```
crc32 0x08000000 0x1000000
```

## Bước 7: Ghi ra file trên thẻ SD

```
fatwrite mmc 0:2 0x08000000 /Home/root/qspi_backup.bin 0x1000000
```

Kết quả đúng: `16777216 bytes written`

## Bước 8: Kiểm tra file

```
fatls mmc 0:2 /Home/root
fatload mmc 0:2 0x09000000 /Home/root/qspi_backup.bin
crc32 0x09000000 0x1000000
cmp.b 0x08000000 0x09000000 0x1000000
```

Kết quả đúng:

- `fatls` hiện file `qspi_backup.bin` dài `16777216` byte.
- CRC ở bước 8 trùng với CRC ở bước 6.
- `cmp.b` báo `Total of 16777216 byte(s) were the same`.

Sau khi boot vào Linux, file nằm tại `/run/media/mmcblk0p2/Home/root/qspi_backup.bin`.

## Khôi phục flash từ file backup (chỉ chạy khi cần)

```
sf probe 0 0 0
mmc rescan
fatload mmc 0:2 0x08000000 /Home/root/qspi_backup.bin
crc32 0x08000000 0x1000000
sf update 0x08000000 0x0 0x1000000
sf read 0x09000000 0x0 0x1000000
cmp.b 0x08000000 0x09000000 0x1000000
```

Kết quả đúng: `cmp.b` báo `Total of 16777216 byte(s) were the same`.
