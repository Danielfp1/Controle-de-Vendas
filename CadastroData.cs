using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Controle_de_Vendas
{
    class CadastroData
    {
        private string userName;
        private string password;
        private string userCpf;

        public string UserName { get => userName; set => userName = value; }
        public string Password { get => password; set => password = value; }
        public string UserCpf { get => userCpf; set => userCpf = value; }
    }
}
