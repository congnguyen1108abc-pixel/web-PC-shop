using Microsoft.AspNetCore.StaticFiles;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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

app.UseAuthorization();

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

