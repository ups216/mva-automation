using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MvaDemo01.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";
            ViewBag.MyMessage = GetAboutUsContent(0);

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }

        private string GetAboutUsContent(int num)
        {
            string message = string.Empty;
            for (int i = 0; i < 100; i++)
            {
                message += "<br/> Test line " + i/num;
            }

            return message;
        }
    }
}