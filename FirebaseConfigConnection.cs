using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Configuration;


namespace Controle_de_Vendas
{
    class FirebaseConfigConnection
    {
        public string BasePath = ConfigurationManager.AppSettings["BasePath"];
        public string AuthScrete = ConfigurationManager.AppSettings["AuthScrete"];
    }
}
