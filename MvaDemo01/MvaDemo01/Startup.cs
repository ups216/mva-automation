using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(MvaDemo01.Startup))]
namespace MvaDemo01
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
