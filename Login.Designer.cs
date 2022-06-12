
namespace Controle_de_Vendas
{
    partial class Login
    {
        /// <summary>
        /// Variável de designer necessária.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Limpar os recursos que estão sendo usados.
        /// </summary>
        /// <param name="disposing">true se for necessário descartar os recursos gerenciados; caso contrário, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Código gerado pelo Windows Form Designer

        /// <summary>
        /// Método necessário para suporte ao Designer - não modifique 
        /// o conteúdo deste método com o editor de código.
        /// </summary>
        private void InitializeComponent()
        {
            this.textBox_email = new System.Windows.Forms.TextBox();
            this.textBox_Senha = new System.Windows.Forms.TextBox();
            this.button_login = new System.Windows.Forms.Button();
            this.button_Cadastar = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.SuspendLayout();
            // 
            // textBox_email
            // 
            this.textBox_email.Location = new System.Drawing.Point(142, 106);
            this.textBox_email.Name = "textBox_email";
            this.textBox_email.Size = new System.Drawing.Size(100, 20);
            this.textBox_email.TabIndex = 9;
            // 
            // textBox_Senha
            // 
            this.textBox_Senha.Location = new System.Drawing.Point(142, 155);
            this.textBox_Senha.Name = "textBox_Senha";
            this.textBox_Senha.Size = new System.Drawing.Size(100, 20);
            this.textBox_Senha.TabIndex = 8;
            this.textBox_Senha.UseSystemPasswordChar = true;
            // 
            // button_login
            // 
            this.button_login.Location = new System.Drawing.Point(152, 195);
            this.button_login.Name = "button_login";
            this.button_login.Size = new System.Drawing.Size(75, 23);
            this.button_login.TabIndex = 10;
            this.button_login.Text = "Login";
            this.button_login.UseVisualStyleBackColor = true;
            this.button_login.Click += new System.EventHandler(this.button_login_Click);
            // 
            // button_Cadastar
            // 
            this.button_Cadastar.Location = new System.Drawing.Point(127, 242);
            this.button_Cadastar.Name = "button_Cadastar";
            this.button_Cadastar.Size = new System.Drawing.Size(128, 23);
            this.button_Cadastar.TabIndex = 11;
            this.button_Cadastar.Text = "Cadastrar Funcionário";
            this.button_Cadastar.UseVisualStyleBackColor = true;
            this.button_Cadastar.Click += new System.EventHandler(this.button_Cadastar_Click);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(177, 90);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(27, 13);
            this.label1.TabIndex = 12;
            this.label1.Text = "CPF";
            // 
            // label3
            // 
            this.label3.Location = new System.Drawing.Point(158, 139);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(69, 13);
            this.label3.TabIndex = 13;
            this.label3.Text = "Senha";
            this.label3.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label2
            // 
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.Location = new System.Drawing.Point(148, 41);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(84, 21);
            this.label2.TabIndex = 14;
            this.label2.Text = "Login";
            this.label2.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // Login
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(409, 308);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.button_Cadastar);
            this.Controls.Add(this.button_login);
            this.Controls.Add(this.textBox_email);
            this.Controls.Add(this.textBox_Senha);
            this.Name = "Login";
            this.Text = "Form1";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox textBox_email;
        private System.Windows.Forms.TextBox textBox_Senha;
        private System.Windows.Forms.Button button_login;
        private System.Windows.Forms.Button button_Cadastar;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label2;
    }
}

