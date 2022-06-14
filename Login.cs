using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using FireSharp.Config;
using FireSharp.Interfaces;
using FireSharp.Response;
using System.Windows.Forms;


namespace Controle_de_Vendas
{
    public partial class Login : Form
    {
      
        public Login()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {

        }

        private async void button_login_Click(object sender, EventArgs e)
        {
            //Adicionar if de conecção com a internet
            FirebaseConfig config = new FirebaseConfig
            {
                AuthSecret = FirebaseConfigConnection.AuthScrete,
                BasePath = FirebaseConfigConnection.BasePath
            };
            IFirebaseClient client = new FireSharp.FirebaseClient(config);

            FirebaseResponse firebaseResponse = await client.GetTaskAsync("Users/" + textBox_email.Text);
            CadastroData cadastroData = firebaseResponse.ResultAs<CadastroData>();

            if (EncryptSHA.GetShaData(textBox_Senha.Text) == cadastroData.Password)
            {
                MessageBox.Show("Logado!");
            }
            else
            {
                MessageBox.Show("Falha no Login!");
            }
        }

        private void button_Cadastar_Click(object sender, EventArgs e)
        {
            Cadastro cadastro = new Cadastro();
            cadastro.Show();
            Hide();
        }
    }
}
