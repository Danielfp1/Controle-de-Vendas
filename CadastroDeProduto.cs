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

        private async void Button_Cadastrar_Click(object sender, EventArgs e)
        {
            {
                bool flagOK = true;
                IFirebaseConfig config = new FirebaseConfig
                {
                    AuthSecret = FirebaseConfigConnection.AuthScrete,
                    BasePath = FirebaseConfigConnection.BasePath
                };
                IFirebaseClient client = new FireSharp.FirebaseClient(config);
                if (true)// Se tiver internet
                {
                    //Verificações
                    if (textBox_NomeDoProduto.Text == "") 
                    {
                        MessageBox.Show("Nome do produto em branco");
                        flagOK = false;
                    }
                    if (textBox_IdProduto.Text == "")
                    {
                        MessageBox.Show("Id do produto em branco");
                        flagOK = false;
                    }
                    if (textBox_Quantidade.Text == "")
                    {
                        MessageBox.Show("Quantidade do produto em branco");
                        flagOK = false;
                    }
                    if (textBox_Valor.Text == "")
                    {
                        MessageBox.Show("Valor do produto em branco");
                        flagOK = false;
                    }
                    if (flagOK)
                    {
                        ProdutoData dados = new ProdutoData
                        {
                            Nome = textBox_NomeDoProduto.Text,
                            Id = textBox_IdProduto.Text,
                            Valor = float.Parse(textBox_Valor.Text),
                            Quantidade = int.Parse(textBox_Quantidade.Text),
                        };
                        SetResponse response = await client.SetTaskAsync("Produtos/" + textBox_IdProduto.Text, dados);
                        ProdutoData result = response.ResultAs<ProdutoData>();
                        MessageBox.Show("Produto Cadastrado!");
                    }
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
