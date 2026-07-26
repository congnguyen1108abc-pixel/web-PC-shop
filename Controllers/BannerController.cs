using Microsoft.AspNetCore.Mvc;
using System;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace PC_Store.Controllers
{
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
        public async Task<IActionResult> UploadVideo(
            [FromForm] string title,
            [FromForm] IFormFile videoFile,
            [FromForm] IFormFile thumbnailFile = null,
            [FromForm] string linkUrl = null,
            [FromForm] int displayOrder = 0)
        {
            try
            {
                // Validate input
                if (string.IsNullOrWhiteSpace(title))
                    return BadRequest(new { error = "Title is required" });

                if (videoFile == null || videoFile.Length == 0)
                    return BadRequest(new { error = "Video file is required" });

                // Check file extensions
                var allowedVideoExtensions = new[] { ".mp4", ".avi", ".mov", ".webm" };
                var videoExtension = Path.GetExtension(videoFile.FileName).ToLower();
                
                if (!Array.Exists(allowedVideoExtensions, ext => ext == videoExtension))
                    return BadRequest(new { error = $"Video format not allowed. Allowed: {string.Join(", ", allowedVideoExtensions)}" });

                // Create directories if not exist
                var uploadsDir = Path.Combine(_env.ContentRootPath, "wwwroot", "assets", "video");
                Directory.CreateDirectory(uploadsDir);

                // Save video file
                var videoFileName = $"banner_video_{DateTime.Now:yyyyMMddHHmmss}_{Guid.NewGuid().ToString("N").Substring(0, 8)}{videoExtension}";
                var videoPath = Path.Combine(uploadsDir, videoFileName);
                
                using (var stream = new FileStream(videoPath, FileMode.Create))
                {
                    await videoFile.CopyToAsync(stream);
                }

                var videoUrl = $"/assets/video/{videoFileName}";

                // Save thumbnail if provided
                string thumbnailUrl = null;
                if (thumbnailFile != null && thumbnailFile.Length > 0)
                {
                    var allowedImageExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
                    var thumbExtension = Path.GetExtension(thumbnailFile.FileName).ToLower();
                    
                    if (Array.Exists(allowedImageExtensions, ext => ext == thumbExtension))
                    {
                        var thumbsDir = Path.Combine(_env.ContentRootPath, "wwwroot", "assets", "image");
                        Directory.CreateDirectory(thumbsDir);

                        var thumbFileName = $"banner_thumb_{DateTime.Now:yyyyMMddHHmmss}_{Guid.NewGuid().ToString("N").Substring(0, 8)}{thumbExtension}";
                        var thumbPath = Path.Combine(thumbsDir, thumbFileName);
                        
                        using (var stream = new FileStream(thumbPath, FileMode.Create))
                        {
                            await thumbnailFile.CopyToAsync(stream);
                        }

                        thumbnailUrl = $"/assets/image/{thumbFileName}";
                    }
                }

                // Return response
                return Ok(new
                {
                    success = true,
                    message = "Video uploaded successfully",
                    data = new
                    {
                        title = title,
                        videoUrl = videoUrl,
                        thumbnailUrl = thumbnailUrl,
                        linkUrl = linkUrl,
                        displayOrder = displayOrder,
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
                // TODO: Query from database using sp_GetHomepageBanners
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
                            videoUrl = "/assets/image/ROGAstralGeForceRTX5090_clip.mp4",
                            thumbnailUrl = "/assets/image/banner_thumb.jpg",
                            linkUrl = null,
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
                // TODO: Delete from database and physical files
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
