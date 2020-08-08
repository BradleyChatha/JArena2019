using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Editor_CSharp.Serial
{
    public abstract class Archive
    {
        public ArchiveObject Root { protected set; get; }

        public abstract IEnumerable<byte> SaveToMemory();
        public abstract void LoadFromMemory(IEnumerable<byte> data);

        public virtual string SaveToMemoryText()
        {
            return System.Text.Encoding.UTF8.GetString(this.SaveToMemory().ToArray());
        }

        public virtual void SaveToFile(string path)
        {
            System.IO.File.WriteAllBytes(path, this.SaveToMemory().ToArray());
        }

        public virtual void LoadFromFile(string path)
        {
            this.LoadFromMemory(System.IO.File.ReadAllBytes(path));
        }
    }
}
