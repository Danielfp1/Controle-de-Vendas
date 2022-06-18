using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Controle_de_Vendas
{
    class ProdutoData
    {
        private string nome;
        private string id;
        private float valor;
        private int quantidade;

        public string Nome { get => nome; set => nome = value; }
        public string Id { get => id; set => id = value; }
        public float Valor { get => valor; set => valor = value; }
        public int Quantidade { get => quantidade; set => quantidade = value; }
    }
}
