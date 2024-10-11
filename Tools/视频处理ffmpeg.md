# 视频处理 ffmpeg

## 概念

* 分辨率：
  
  * 分辨率指的是视频的横纵坐标多少个像素点，通过分辨率，我们能计算出来一张图片的大小，比如一张 1920 * 1080 的图片，大小为 5.93MB (对于RGB像素，一个像素点的一个通道是0-255，为2^8，为1bit，一个像素3个通道，为3bit，一共 1920x1080x3/1024/1024=5.93MB)。可以通过windows的画图，产生一个空白图片，保存成 bmp（24位位图）查看。

* 帧率
  
  - 一秒出现多少个画面。比如60帧，表示一秒60张画面。30帧，表示一秒30个画面。
- 码率：
  
  -  有时候也叫数据速率，或者比特率。虽然理论上，码率越高，视频质量越好，但一旦码率到某个值，再提升也没有更好的效果。因此调整码率，是一种既能保证视频质量，又能压缩视频的比较好的方式。一般3Mbps -- 6Mbps 就已经足够了。为了保证视频质量，在第一次压缩的时候，可以先尝试6Mbps，然后看下效果是否满意，然后根据文件大小，再做进一步调整
* 编码
  
  * 编码决定了视频实际上是以什么方式存储在硬盘上的，因此不同的编码，文件的大小也不一样。目前最流行的是 H264 AVC。也有部分使用 H265，H265比H264压缩做的更好一些，但考虑兼容性的问题(以及性能)，目前H264依然是最流行的编码格式

* 封装格式
  
  * 也可以理解为是容器格式。实际封装格式是将视频流(视频流1，视频流2)、音频流(音频流1，音频流2)、字幕、元数据。视频流和音频流分别可以有不同的编码格式

## 国内视频播放平台的视频格式对比

以长津湖电影为例

| 网站   | 爱奇艺             | 优酷              | 腾讯视频       | 芒果TV            | 咪咕视频            | 乐视视频            |
| ---- | --------------- | --------------- | ---------- | --------------- | --------------- | --------------- |
| 编码   | H264 AVC        | H264 AVC        | H264 AVC   | H264 AVC        | H264 AVC        | H264 AVC        |
| 封装格式 | mp4             | mp4             | mp4        | mp4             | mp4             | mp4             |
| 加密   | qsv 加密          | kux 加密          | qlv 加密     | 无               | 无               | 无               |
| 视频码率 | 1749 kb/s       | 1536kb/s        | 2373kb/s   | 3413kb/s        | 3473kb/s        | 2993kb/s        |
| 音频码率 | 192kb/s/44.1khz | 126kb/s/44.1khz | 93kb/48khz | 126kb/s/44.1khz | 126kb/s/44.1khz | 128kb/s/44.1khz |
| 分辨率  | 1820*816        | 1920*816        | 1820*816   | 1920*818        | 1890*800        | 1920*816        |
| 帧数   | 24              | 24              | 24         | 25              | 25              | 25              |
| 文件大小 | 2.4GB           | 1.93GB          | 3.07GB     | 4.39GB          | 4.45GB          | 3GB+            |

以miui系统录制屏幕为例，得到的视频的码率为3280kbps，帧数为 24.27帧/秒，分辨率为2400*1080，录制57s的屏幕，视频大小为24MB(粗略算来，录制2个小时为3GB)

## ffmpeg使用

### 初步使用

默认情况下，ffmpeg会根据输出的文件后缀，来自动指定文件格式，比如我们要将一个mp4的文件，使用默认的配置参数，转换成一个新的mp4文件

```shell
ffmpeg -i input.mp4 output.mp4
```

当然我们也可以手动指定视频的编码格式，其中 libx264 是 ffmpeg实现的一种纯用软件实现的编码器；如果使用的是 Nvidia显卡，可以用h265_nvenc 来实现硬件加速(需要注意的是，需要硬件支持，并安装对应的[驱动](https://developer.nvidia.com/nvidia-video-codec-sdk/download))。据说硬件编码虽然时间快，但是体积会更大，质量会差一些，需要显卡支持，因此如果时间充足，不建议使用

```shell
ffmpeg -i input.mp4 -c:v libx264 output.mp4
ffmpeg -i input.mp4 -c:v h264_nvenc output.mp4 
```

### 使用预设值

在转换视频的时候，也可以设置一些其他的参数，来压缩视频文件的大小，我们也可以使用通过 -preset 参数一些预设值，来帮我们快速设置参数，这个参数的取值可以是：ultrafast, superfast, veryfast, faster, fast, medium(默认), slow, slower, veryslow。选择 ultrafast 会有最快的编码速度，但会产生一个较大的文件，而veryslow虽然速度慢，但生成文件小

```shell
ffmpeg -i input -c:v libx264 -preset veryfast -out output.mp4
```

### 通过 crf 控制图像质量

crf 可以控制图像的质量，取值范围为0-51，数值越大，图像质量越差。0表示无损压缩。实际中最常用的是19-28

```shell
ffmpeg -i input.mp4 -c:v libx264 -crf 22 output.mp4
```

### 剪切与合并

* 剪切
  
  通过 -ss 指定起始位置，-t 指定时长。需要注意的是：-ss需要放在 -i 之后，这样更准确。如果 -ss 放在了 -i 之前，那么使用的是关键帧定位，虽然定位速度很快，但可能会有一点点偏差(这种方法适合时长比较长的视频)。也可以使用 -to 来替代 -t，直接指定终止的位置。

* 合并
  
  需要将视频的所有文件放在一个文本文件中，如命名为 mylist.txt
  
  ```textile
  file 'clip1.mp4'
  file 'clip2.mp4'
  file 'clip4.mp4'
  ...
  ```
  
  然后通过 -f 指定为拼接， -i 指定视频的列表，-c copy表示不希望重新编码而是直接拷贝原始视频的内容
  
  ```shell
  ffmpeg -f concat -i mylist.txt -c copy output.mp4
  ```

### ffmpeg 小技巧

#### 创建缩略图

使用两个过滤器 : fps 表示输出文件的帧率，1/10表示每10秒输出一帧的画面，scale表示输出的图像大小为720p，最后是文件名

```shell
ffmpeg -i input.mp4 -vf "fps=1/10,scale=-2:720" thumbnail-%03d.jpg
```

#### 给视频添加水印

先准备一个水印图片，比如test.jpg，通过一个过滤器 overlay 表示将图片叠加到视频上, 100:100 表示水印图像在视频中的位置（图像左上角的坐标）

```shell
ffmpeg -i input.mp4 -i test.jpg -filter_complex "overlay=100:100" output.mp4
```

#### Gif 动图转换

由于gif动图的特性，不太适合转换太长的视频，我们以只产生3s的 gif动图为例，fps为每15秒产生一帧，scale指定图像为256p，前面的-1表示根据横坐标256自动调整；从split开始到最后paletteuse是因为 gif自身256色的限制，需要一个单独的调色板。

```shell
ffmpeg -i input.mp4 -ss0 -t 3 -filter_complex [0:v]fps=15,scale=-1:256,split[a][b];[a]palettegen[p];[b][p]paletteuse output.gif
```

#### ffmpeg 录制屏幕

效率上可能不如 OBS , ShadowPlay 这些工具，但使用起来不需要安装较重的软件，比较轻量

```shell
ffmpeg -hide_banner -loglevel error -stats -f gdigrab -framerate 60 -offset_x 0 -offset_y 0 -video_size 1920x1080 -draw_mouse 1 -i desktop -c:v libx264 -r 60 -preset ultrafast -pix_fmt yuv420p -y screen_record.mp4
```

### ffmpeg 的log level

可以通过 -loglevel 来指定 log 级别

```shell
ffmpeg -i test.avi -loglevel error -c:v libx264 output.mp4 -y
```

## 学习视频

[FFmpeg 最最强大的视频工具 (转码/压缩/剪辑/滤镜/水印/录屏/Gif/...)_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1AT411J7cH?spm_id_from=333.999.0.0&vd_source=2038118a3af8a3d09500b0fe57575051)
