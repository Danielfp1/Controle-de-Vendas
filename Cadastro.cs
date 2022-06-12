﻿using System;
using static System.Guid;
using System.Threading.Tasks;
using System.Windows.Forms;
using FireSharp.Config;
using FireSharp.Interfaces;
using FireSharp.Response;

namespace Controle_de_Vendas
{
    public partial class Cadastro : Form
    {
        private Button Button_Cadastrar;
        private TextBox textBox_Nome;
        private TextBox textBox_Cpf;
        private TextBox textBox_ConfirmarSenha;
        private Label label1;
        private Label label2;
        private Label label3;
        private Label label4;
        private TextBox textBox_Senha;

        
        public Cadastro()
        {
            InitializeComponent();
        }


        private void InitializeComponent()
        {
            this.Button_Cadastrar = new System.Windows.Forms.Button();
            this.textBox_Nome = new System.Windows.Forms.TextBox();
            this.textBox_Cpf = new System.Windows.Forms.TextBox();
            this.textBox_ConfirmarSenha = new System.Windows.Forms.TextBox();
            this.textBox_Senha = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.SuspendLayout();
            // 
            // Button_Cadastrar
            // 
            this.Button_Cadastrar.Location = new System.Drawing.Point(124, 231);
            this.Button_Cadastrar.Name = "Button_Cadastrar";
            this.Button_Cadastrar.Size = new System.Drawing.Size(75, 23);
            this.Button_Cadastrar.TabIndex = 9;
            this.Button_Cadastrar.Text = "Cadastrar";
            this.Button_Cadastrar.UseVisualStyleBackColor = true;
            this.Button_Cadastrar.Click += new System.EventHandler(this.Button_Cadastrar_Click);
            // 
            // textBox_Nome
            // 
            this.textBox_Nome.Location = new System.Drawing.Point(114, 45);
            this.textBox_Nome.Name = "textBox_Nome";
            this.textBox_Nome.Size = new System.Drawing.Size(100, 20);
            this.textBox_Nome.TabIndex = 8;
            // 
            // textBox_email
            // 
            this.textBox_Cpf.Location = new System.Drawing.Point(114, 96);
            this.textBox_Cpf.Name = "textBox_Cpf";
            this.textBox_Cpf.Size = new System.Drawing.Size(100, 20);
            this.textBox_Cpf.TabIndex = 7;
            // 
            // textBox_ConfirmarSenha
            // 
            this.textBox_ConfirmarSenha.Location = new System.Drawing.Point(114, 195);
            this.textBox_ConfirmarSenha.Name = "textBox_ConfirmarSenha";
            this.textBox_ConfirmarSenha.Size = new System.Drawing.Size(100, 20);
            this.textBox_ConfirmarSenha.TabIndex = 6;
            // 
            // textBox_Senha
            // 
            this.textBox_Senha.Location = new System.Drawing.Point(114, 145);
            this.textBox_Senha.Name = "textBox_Senha";
            this.textBox_Senha.Size = new System.Drawing.Size(100, 20);
            this.textBox_Senha.TabIndex = 5;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(147, 29);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(35, 13);
            this.label1.TabIndex = 10;
            this.label1.Text = "Nome";
            this.label1.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label2
            // 
            this.label2.Location = new System.Drawing.Point(147, 80);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(35, 13);
            this.label2.TabIndex = 11;
            this.label2.Text = "CPF";
            this.label2.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label3
            // 
            this.label3.Location = new System.Drawing.Point(130, 129);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(69, 13);
            this.label3.TabIndex = 12;
            this.label3.Text = "Senha";
            this.label3.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label4
            // 
            this.label4.Location = new System.Drawing.Point(116, 179);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(98, 13);
            this.label4.TabIndex = 13;
            this.label4.Text = "Confirmar Senha";
            this.label4.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // Cadastro
            // 
            this.ClientSize = new System.Drawing.Size(324, 308);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.Button_Cadastrar);
            this.Controls.Add(this.textBox_Nome);
            this.Controls.Add(this.textBox_Cpf);
            this.Controls.Add(this.textBox_ConfirmarSenha);
            this.Controls.Add(this.textBox_Senha);
            this.Name = "Cadastro";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        private async void Button_Cadastrar_Click(object sender, EventArgs e)
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
                    Password = textBox_Senha.Text,
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
}
