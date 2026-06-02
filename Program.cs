using Microsoft.AspNetCore.StaticFiles;
using PC_Store.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Dang ky Chatbot Service voi Google Gemini API (Free)
var geminiApiKey = builder.Configuration["Gemini:ApiKey"];
if (string.IsNullOrEmpty(geminiApiKey))
{
    Console.WriteLine("Canh bao: Gemini:ApiKey khong duoc cau hinh trong appsettings.json");
}
builder.Services.AddScoped<IChatbotService>(sp =>
    new ChatbotService(geminiApiKey ?? "")
);

// Them CORS de frontend co the goi API
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

var app = builder.Build();

app.UseDefaultFiles();
var provider = new FileExtensionContentTypeProvider();
provider.Mappings[".glb"] = "model/gltf-binary";
provider.Mappings[".gltf"] = "model/gltf+json";

app.UseStaticFiles(new StaticFileOptions
{
    ContentTypeProvider = provider
});

app.UseSwagger();
app.UseSwaggerUI();

app.UseHttpsRedirection();

// Su dung CORS
app.UseCors("AllowAll");

app.UseAuthorization();

app.MapGet("/welcome", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "welcome.html"));
});

app.MapGet("/welcome.html", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "welcome.html"));
});

app.MapGet("/Homepage", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "homepage.html"));
});

app.MapGet("/Login", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "login.html"));
});

app.MapGet("/Products", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "products.html"));
});

app.MapGet("/shoppingcart", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "shoppingcart.html"));
});

app.MapGet("/filladdress", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "filladdress.html"));
});

app.MapGet("/payments", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "payments.html"));
});

app.MapGet("/paymentcomplete", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "paymentcomplete.html"));
});

app.MapGet("/paymentcomplete.html", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "paymentcomplete.html"));
});

app.MapGet("/qr-pay", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "qr-pay.html"));
});

app.MapGet("/qr-pay.html", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "qr-pay.html"));
});

app.MapPost("/Login", async context =>
{
    // Dummy login: redirect to Homepage
    context.Response.Redirect("/Homepage");
});

app.MapGet("/Register", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.SendFileAsync(Path.Combine(builder.Environment.ContentRootPath, "Page", "register.html"));
});

app.MapControllers();

app.Run();