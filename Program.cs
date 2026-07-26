using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using PC_Store.Helpers;
using PC_Store.Hubs;
using PC_Store.Middleware;
using PC_Store.Repositories;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services;
using PC_Store.Services.Interfaces;
using System.Data;
using System.Text;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

// ── MVC / Swagger ─────────────────────────────────────────────────────────────
builder.Services.AddControllers()
    .AddJsonOptions(opts =>
        opts.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase);
builder.Services.AddEndpointsApiExplorer();

// ── Form Upload Limits ────────────────────────────────────────────────────────
builder.Services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 524288000; // 500 MB
});

// ── SignalR (built-in, không cần package ngoài) ────────────────────────────
builder.Services.AddSignalR();
builder.Services.AddScoped<INotificationPusher, NotificationPusher>();

builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "PC_Store API",
        Version = "v1"
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Nhập token dạng: Bearer {your token}"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new List<string>()
        }
    });
});

// ── CORS ──────────────────────────────────────────────────────────────────────
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod());
});

// ── JWT Authentication ────────────────────────────────────────────────────────
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var key = builder.Configuration["Jwt:Key"] ?? string.Empty;

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,

            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(key)
            )
        };
    });

builder.Services.AddAuthorization();

// ── Database ──────────────────────────────────────────────────────────────────
builder.Services.AddScoped<IDbConnection>(_ =>
    DbHelper.CreateConnection(
        builder.Configuration.GetConnectionString("DefaultConnection")
    )
);

// ── Base Repository ───────────────────────────────────────────────────────────
builder.Services.AddScoped<IDbRepository, DbRepository>();

// ── Domain Repositories ───────────────────────────────────────────────────────
builder.Services.AddScoped<IAuthRepository, AuthRepository>();
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<ICategoryRepository, CategoryRepository>();
builder.Services.AddScoped<IBrandRepository, BrandRepository>();
builder.Services.AddScoped<ICartRepository, CartRepository>();
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IDashboardRepository, DashboardRepository>();
builder.Services.AddScoped<IBannerRepository, BannerRepository>();
builder.Services.AddScoped<IVoucherRepository, VoucherRepository>();
builder.Services.AddScoped<IReviewRepository, ReviewRepository>();
builder.Services.AddScoped<IWarrantyRepository, WarrantyRepository>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<IChatRepository, ChatRepository>();
builder.Services.AddScoped<IReturnRepository, ReturnRepository>();

// ── Domain Services ───────────────────────────────────────────────────────────
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IBrandService, BrandService>();
builder.Services.AddScoped<ICartService, CartService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IBannerService, BannerService>();
builder.Services.AddScoped<IVoucherService, VoucherService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IWarrantyService, WarrantyService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IChatService, ChatService>();
builder.Services.AddScoped<RecommendationDAO>();
builder.Services.AddSingleton<AprioriAlgorithm>();
builder.Services.AddScoped<IRecommendationService, RecommendationService>();
builder.Services.AddScoped<IHighUtilityMiningService, HighUtilityMiningService>();

// ── Return / Refund Services ──────────────────────────────────────────────────
builder.Services.AddHttpClient<IGhnService, GhnService>();
builder.Services.AddScoped<IGhnService, GhnService>();
builder.Services.AddScoped<IReturnService, ReturnService>();
builder.Services.AddHostedService<GhnStatusPollingService>();

// ── Email Service (Brevo & General SMTP) ──────────────────────────────────────
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IEmailService, BrevoEmailService>();

// ── SePay Payment Service ─────────────────────────────────────────────────────
builder.Services.AddHttpClient<ISePayService, SePayService>();
builder.Services.AddScoped<ISePayService, SePayService>();

// ── Cache Service (MemoryCache) ───────────────────────────────────────────────
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<ICacheService, CacheService>();

// ── Rate Limiting (built-in .NET 10, không cần package ngoài) ────────────────
builder.Services.AddRateLimiter(options =>
{
    options.OnRejected = async (context, cancellationToken) =>
    {
        context.HttpContext.Response.StatusCode  = StatusCodes.Status429TooManyRequests;
        context.HttpContext.Response.ContentType = "application/json; charset=utf-8";

        if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
        {
            context.HttpContext.Response.Headers.RetryAfter =
                ((int)retryAfter.TotalSeconds).ToString();
        }

        await context.HttpContext.Response.WriteAsync(
            """{\"success\":false,\"statusCode\":429,\"message\":\"Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau ít phút.\"}""",
            cancellationToken);
    };

    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
    {
        var path = httpContext.Request.Path.Value ?? "";
        
        // Không áp dụng rate limit cho các trang tĩnh, hình ảnh, CSS, JS (các request không thuộc /api)
        if (!path.StartsWith("/api", StringComparison.OrdinalIgnoreCase))
        {
            return RateLimitPartition.GetNoLimiter("static_bypass");
        }

        var ip = httpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                 ?? httpContext.Connection.RemoteIpAddress?.ToString()
                 ?? "unknown";

        return RateLimitPartition.GetSlidingWindowLimiter(
            partitionKey: $"global:{ip}",
            factory: _ => new SlidingWindowRateLimiterOptions
            {
                PermitLimit              = 500, // Tăng nhẹ giới hạn cho các API thực tế
                Window                   = TimeSpan.FromMinutes(1),
                SegmentsPerWindow        = 6,
                QueueProcessingOrder     = QueueProcessingOrder.OldestFirst,
                QueueLimit               = 0
            });
    });

    options.AddPolicy("auth", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"auth:{httpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault() ?? httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown"}",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit          = 5,
                Window               = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit           = 0
            }));

    options.AddPolicy("auth-check", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"auth-check:{httpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault() ?? httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown"}",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit          = 20,
                Window               = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit           = 0
            }));

    options.AddPolicy("order", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"order:{httpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault() ?? httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown"}",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit          = 5,
                Window               = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit           = 0
            }));

    options.AddPolicy("write", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"write:{httpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault() ?? httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown"}",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit          = 30,
                Window               = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit           = 0
            }));
});

// Dang ky Chatbot Service voi Google Gemini API (Free)
var geminiApiKey = builder.Configuration["Gemini:ApiKey"];
if (string.IsNullOrEmpty(geminiApiKey))
{
    Console.WriteLine("Canh bao: Gemini:ApiKey khong duoc cau hinh trong appsettings.json");
}
builder.Services.AddScoped<IChatbotService>(sp =>
    new ChatbotService(geminiApiKey ?? "")
);

var app = builder.Build();

// Auto-restore clip assets from D:\DoAnTMDT\Clip if they are missing
try {
    string srcClipDir = @"d:\DoAnTMDT\Clip";
    string destClipDir = Path.Combine(app.Environment.ContentRootPath, "wwwroot", "assets", "image");
    if (Directory.Exists(srcClipDir)) {
        Directory.CreateDirectory(destClipDir);
        string file1 = Path.Combine(destClipDir, "PCGaming_clip.mp4");
        string file2 = Path.Combine(destClipDir, "ROGAstralGeForceRTX5090_clip.mp4");
        if (!File.Exists(file1)) {
            File.Copy(Path.Combine(srcClipDir, "PCGaming_clip.mp4"), file1, true);
        }
        if (!File.Exists(file2)) {
            File.Copy(Path.Combine(srcClipDir, "ROGAstralGeForceRTX5090_clip.mp4"), file2, true);
        }
    }
} catch (Exception) {}

// ── Static Files ───────────────────────────────────────────────────────────────
app.UseStaticFiles();
app.UseDefaultFiles();
var provider = new FileExtensionContentTypeProvider();
provider.Mappings[".glb"] = "model/gltf-binary";
provider.Mappings[".gltf"] = "model/gltf+json";

app.UseStaticFiles(new StaticFileOptions
{
    ContentTypeProvider = provider
});

// ── Swagger ───────────────────────────────────────────────────────────────────
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "PC_Store API v1");
    
    // Enable dark mode toggle button
    options.InjectStylesheet("/swagger-ui/custom.css");
    options.InjectJavascript("/swagger-ui/custom.js");
});

// ── Global Error Handling ────────────────────────────────────────────────────
app.UseMiddleware<ExceptionHandlingMiddleware>();

// ── Rate Limiting ─────────────────────────────────────────────────────────────
app.UseRateLimiter();

// Su dung CORS
app.UseCors();

app.UseAuthentication();
app.UseAuthorization();

// ── Dynamic Page Routing ───────────────────────────────────────────────────────
app.Use(async (context, next) =>
{
    var path = context.Request.Path.Value ?? "";
    
    // Skip API, Hubs, Swagger
    if (path.StartsWith("/api", StringComparison.OrdinalIgnoreCase) ||
        path.StartsWith("/hubs", StringComparison.OrdinalIgnoreCase) ||
        path.StartsWith("/swagger", StringComparison.OrdinalIgnoreCase))
    {
        await next();
        return;
    }

    // Special redirect for /profile to /profile/info
    if (path.Equals("/profile", StringComparison.OrdinalIgnoreCase) ||
        path.Equals("/profile/", StringComparison.OrdinalIgnoreCase))
    {
        context.Response.Redirect("/profile/info");
        return;
    }

    // Resolve relative path
    var relativePath = path.TrimStart('/');
    if (relativePath.EndsWith(".html", StringComparison.OrdinalIgnoreCase))
    {
        relativePath = relativePath.Substring(0, relativePath.Length - 5);
    }

    // Default to homepage if path is empty
    if (string.IsNullOrEmpty(relativePath))
    {
        relativePath = "homepage";
    }

    // Normalize path to prevent directory traversal
    var sanitizedPath = relativePath.Replace("..", "").Replace("\\", "/");
    var htmlFilePath = Path.Combine(builder.Environment.ContentRootPath, "Page", sanitizedPath + ".html");

    if (File.Exists(htmlFilePath))
    {
        context.Response.ContentType = "text/html";
        await context.Response.SendFileAsync(htmlFilePath);
        return;
    }

    await next();
});

app.MapGet("/Register", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "register.html"));
});

app.MapGet("/forgot-password", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "forgot-password.html"));
});

app.MapGet("/reset-password", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "reset-password.html"));
});

app.MapGet("/voucher", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "voucher.html"));
});

app.MapGet("/product-detail", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "product-detail.html"));
});

app.MapGet("/product/{slug}", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "product-detail.html"));
});

// ── API Controllers ───────────────────────────────────────────────────────────
app.MapGet("/admin-banner-upload", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "admin-banner-upload.html"));
});

app.MapControllers();

// ── SignalR Hub Endpoint ──────────────────────────────────────────────────────
app.MapHub<NotificationHub>("/hubs/notification");

app.Run();