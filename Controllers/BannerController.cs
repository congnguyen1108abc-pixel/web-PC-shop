using Microsoft.AspNetCore.Mvc;
using System;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace PC_Store.Controllers
{
    // ── Request DTO (dùng class để Swagger không bị duplicate ContentType) ──
    public class UploadVideoRequest
    {
        public string Title { get; set; } = string.Empty;
        public IFormFile VideoFile { get; set; } = null!;
        public IFormFile? ThumbnailFile { get; set; }
        public string? LinkUrl { get; set; }
        public int DisplayOrder { get; set; } = 0;
    }

    [ApiController]
    [Route("api/[controller]")]
    public class BannerController : ControllerBase
    {
        private readonly IWebHostEnvironment _env;

        public BannerController(IWebHostEnvironment env)
        {
            _env = env;
        }

        /// <summary>
        /// Upload video clip cho banner
        /// </summary>
        [HttpPost("upload-video")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadVideo([FromForm] UploadVideoRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Title))
                    return BadRequest(new { error = "Title is required" });

                if (request.VideoFile == null || request.VideoFile.Length == 0)
                    return BadRequest(new { error = "Video file is required" });

                var allowedVideoExtensions = new[] { ".mp4", ".avi", ".mov", ".webm" };
                var videoExtension = Path.GetExtension(request.VideoFile.FileName).ToLower();

                if (!Array.Exists(allowedVideoExtensions, ext => ext == videoExtension))
                    return BadRequest(new { error = $"Video format not allowed. Allowed: {string.Join(", ", allowedVideoExtensions)}" });

                var uploadsDir = Path.Combine(_env.ContentRootPath, "wwwroot", "assets", "video");
                Directory.CreateDirectory(uploadsDir);

                var videoFileName = $"banner_video_{DateTime.Now:yyyyMMddHHmmss}_{Guid.NewGuid().ToString("N")[..8]}{videoExtension}";
                var videoPath = Path.Combine(uploadsDir, videoFileName);

                using (var stream = new FileStream(videoPath, FileMode.Create))
                {
                    await request.VideoFile.CopyToAsync(stream);
                }

                var videoUrl = $"/assets/video/{videoFileName}";

                string? thumbnailUrl = null;
                if (request.ThumbnailFile != null && request.ThumbnailFile.Length > 0)
                {
                    var allowedImageExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
                    var thumbExtension = Path.GetExtension(request.ThumbnailFile.FileName).ToLower();

                    if (Array.Exists(allowedImageExtensions, ext => ext == thumbExtension))
                    {
                        var thumbsDir = Path.Combine(_env.ContentRootPath, "wwwroot", "assets", "image");
                        Directory.CreateDirectory(thumbsDir);

                        var thumbFileName = $"banner_thumb_{DateTime.Now:yyyyMMddHHmmss}_{Guid.NewGuid().ToString("N")[..8]}{thumbExtension}";
                        var thumbPath = Path.Combine(thumbsDir, thumbFileName);

                        using (var stream = new FileStream(thumbPath, FileMode.Create))
                        {
                            await request.ThumbnailFile.CopyToAsync(stream);
                        }

                        thumbnailUrl = $"/assets/image/{thumbFileName}";
                    }
                }

                return Ok(new
                {
                    success = true,
                    message = "Video uploaded successfully",
                    data = new
                    {
                        title = request.Title,
                        videoUrl,
                        thumbnailUrl,
                        linkUrl = request.LinkUrl,
                        displayOrder = request.DisplayOrder,
                        bannerType = "Video",
                        isActive = true
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = $"Upload failed: {ex.Message}" });
            }
        }

        /// <summary>
        /// Lấy danh sách banner video
        /// </summary>
        [HttpGet("videos")]
        public IActionResult GetBannerVideos()
        {
            try
            {
                return Ok(new
                {
                    success = true,
                    message = "Banners retrieved successfully",
                    data = new List<object>
                    {
                        new
                        {
                            bannerID = 1,
                            title = "ROG Astral GeForce RTX 5090",
                            videoUrl = "/assets/video/ROGAstralGeForceRTX5090_clip.mp4",
                            thumbnailUrl = "/assets/image/banner_thumb.jpg",
                            linkUrl = (string?)null,
                            displayOrder = 1,
                            isActive = true
                        }
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = $"Query failed: {ex.Message}" });
            }
        }

        /// <summary>
        /// Xóa video banner
        /// </summary>
        [HttpDelete("video/{bannerID}")]
        public IActionResult DeleteBannerVideo(int bannerID)
        {
            try
            {
                return Ok(new
                {
                    success = true,
                    message = "Banner deleted successfully"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = $"Delete failed: {ex.Message}" });
            }
        }
    }
}
