using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using FireSharp.Config;
using FireSharp.Interfaces;
using FireSharp.Response;

namespace Controle_de_Vendas
{
    public partial class CadastroDeProduto : Form
    {
        public CadastroDeProduto()
        {
            InitializeComponent();
        }

        private void Button_Cadastrar_Click(object sender, EventArgs e)
        {
            {
                IFirebaseConfig config = new FirebaseConfig
                {
                    AuthSecret = FirebaseConfigConnection.AuthScrete,
                    BasePath = FirebaseConfigConnection.BasePath
                };
                IFirebaseClient client = new FireSharp.FirebaseClient(config);
                if (true)// Se tiver internet
                {
                    CadastroData dados = new CadastroData
                    {
                        UserName = textBox_Nome.Text,
                        UserCpf = textBox_Cpf.Text,
                        Password = EncryptSHA.GetShaData(textBox_Senha.Text),
                    };
                    SetResponse response = await client.SetTaskAsync("Users/" + textBox_Cpf.Text, dados);
                    CadastroData result = response.ResultAs<CadastroData>();
                    MessageBox.Show("Cadastro Realizado!");

                }
                else
                {
                    MessageBox.Show("Sem conecção com a internet");
                }
            }
        }

        private void label4_Click(object sender, EventArgs e)
        {

        }
    }
}
