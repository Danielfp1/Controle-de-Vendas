
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
            this.SuspendLayout();
            // 
            // textBox_email
            // 
            this.textBox_email.Location = new System.Drawing.Point(187, 120);
            this.textBox_email.Name = "textBox_email";
            this.textBox_email.Size = new System.Drawing.Size(100, 20);
            this.textBox_email.TabIndex = 9;
            // 
            // textBox_Senha
            // 
            this.textBox_Senha.Location = new System.Drawing.Point(187, 169);
            this.textBox_Senha.Name = "textBox_Senha";
            this.textBox_Senha.Size = new System.Drawing.Size(100, 20);
            this.textBox_Senha.TabIndex = 8;
            // 
            // button_login
            // 
            this.button_login.Location = new System.Drawing.Point(196, 227);
            this.button_login.Name = "button_login";
            this.button_login.Size = new System.Drawing.Size(75, 23);
            this.button_login.TabIndex = 10;
            this.button_login.Text = "Login";
            this.button_login.UseVisualStyleBackColor = true;
            this.button_login.Click += new System.EventHandler(this.button_login_Click);
            // 
            // Login
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(474, 308);
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
    }
}

