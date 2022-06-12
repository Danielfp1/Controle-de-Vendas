using System;
using System.Text;
using System.Security.Cryptography;

namespace Controle_de_Vendas
{
    class EncryptSHA
    {
        public static string GetShaData(string data)
        {
            SHA1 sha = SHA1.Create();
            byte[] hashData = sha.ComputeHash(Encoding.Default.GetBytes(data));
            StringBuilder returnValue = new StringBuilder();
            int i;
            for (i = 0; i < hashData.Length - 1; i++)
            {
                returnValue.Append(hashData[i].ToString());
            }
            return returnValue.ToString();
        }
    }
}
