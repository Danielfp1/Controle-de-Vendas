
namespace Controle_de_Vendas
{
    partial class CadastroDeProduto
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.label2 = new System.Windows.Forms.Label();
            this.textBox_NomeDoProduto = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.textBox_IdProduto = new System.Windows.Forms.TextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.textBox_Valor = new System.Windows.Forms.TextBox();
            this.Button_Cadastrar = new System.Windows.Forms.Button();
            this.label4 = new System.Windows.Forms.Label();
            this.textBox_Quantidade = new System.Windows.Forms.TextBox();
            this.label5 = new System.Windows.Forms.Label();
            this.SuspendLayout();
            // 
            // label2
            // 
            this.label2.Location = new System.Drawing.Point(71, 61);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(115, 13);
            this.label2.TabIndex = 13;
            this.label2.Text = "Nome do Produto";
            this.label2.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // textBox_NomeDoProduto
            // 
            this.textBox_NomeDoProduto.Location = new System.Drawing.Point(74, 77);
            this.textBox_NomeDoProduto.Name = "textBox_NomeDoProduto";
            this.textBox_NomeDoProduto.Size = new System.Drawing.Size(100, 20);
            this.textBox_NomeDoProduto.TabIndex = 12;
            // 
            // label1
            // 
            this.label1.Location = new System.Drawing.Point(71, 131);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(115, 13);
            this.label1.TabIndex = 15;
            this.label1.Text = "Id do Produto";
            this.label1.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // textBox_IdProduto
            // 
            this.textBox_IdProduto.Location = new System.Drawing.Point(74, 147);
            this.textBox_IdProduto.Name = "textBox_IdProduto";
            this.textBox_IdProduto.Size = new System.Drawing.Size(100, 20);
            this.textBox_IdProduto.TabIndex = 14;
            // 
            // label3
            // 
            this.label3.Location = new System.Drawing.Point(71, 195);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(115, 13);
            this.label3.TabIndex = 17;
            this.label3.Text = "Valor";
            this.label3.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // textBox_Valor
            // 
            this.textBox_Valor.Location = new System.Drawing.Point(74, 211);
            this.textBox_Valor.Name = "textBox_Valor";
            this.textBox_Valor.Size = new System.Drawing.Size(100, 20);
            this.textBox_Valor.TabIndex = 16;
            // 
            // Button_Cadastrar
            // 
            this.Button_Cadastrar.Location = new System.Drawing.Point(84, 325);
            this.Button_Cadastrar.Name = "Button_Cadastrar";
            this.Button_Cadastrar.Size = new System.Drawing.Size(75, 23);
            this.Button_Cadastrar.TabIndex = 18;
            this.Button_Cadastrar.Text = "Cadastrar";
            this.Button_Cadastrar.UseVisualStyleBackColor = true;
            this.Button_Cadastrar.Click += new System.EventHandler(this.Button_Cadastrar_Click);
            // 
            // label4
            // 
            this.label4.Location = new System.Drawing.Point(71, 261);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(115, 13);
            this.label4.TabIndex = 20;
            this.label4.Text = "Quantidade";
            this.label4.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.label4.Click += new System.EventHandler(this.label4_Click);
            // 
            // textBox_Quantidade
            // 
            this.textBox_Quantidade.Location = new System.Drawing.Point(74, 277);
            this.textBox_Quantidade.Name = "textBox_Quantidade";
            this.textBox_Quantidade.Size = new System.Drawing.Size(100, 20);
            this.textBox_Quantidade.TabIndex = 19;
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label5.Location = new System.Drawing.Point(42, 25);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(175, 20);
            this.label5.TabIndex = 21;
            this.label5.Text = "Cadastro de Produto";
            this.label5.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // CadastroDeProduto
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(266, 385);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.textBox_Quantidade);
            this.Controls.Add(this.Button_Cadastrar);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.textBox_Valor);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.textBox_IdProduto);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.textBox_NomeDoProduto);
            this.Name = "CadastroDeProduto";
            this.Text = "Form1";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.TextBox textBox_NomeDoProduto;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox textBox_IdProduto;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox textBox_Valor;
        private System.Windows.Forms.Button Button_Cadastrar;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.TextBox textBox_Quantidade;
        private System.Windows.Forms.Label label5;
    }
}