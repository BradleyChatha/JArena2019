using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Editor_CSharp.Serial
{
    public class ArchiveObject
    {
        public class Attribute
        {
            public string       Name;
            public ArchiveValue Value;
        }

        public string               Name;
        public List<Attribute>      Attributes;
        public List<ArchiveValue>   Values;
        public List<ArchiveObject>  Children;

        public ArchiveObject(string name = "")
        {
            this.Name = name;
            this.Attributes = new List<Attribute>();
            this.Values = new List<ArchiveValue>();
            this.Children = new List<ArchiveObject>();
        }

        public void SetAttribute(string name, ArchiveValue value)
        {
            var index = this.Attributes.FindIndex(a => a.Name == name);
            if(index == -1)
                this.Attributes.Add(new Attribute(){ Name = name, Value = value });
            else
                this.Attributes[index] = new Attribute(){ Name = name, Value = value };
        }

        public void AddValue(ArchiveValue value)
        {
            this.Values.Add(value);
        }

        public void AddChild(ArchiveObject child)
        {
            if(child == null)
                throw new ArgumentNullException("child");

            this.Children.Add(child);
        }

        public ArchiveValue GetAttribute(string name, Lazy<ArchiveValue> default_ = null)
        {
            var index = this.Attributes.FindIndex(a => a.Name == name);
            return (index != -1) ? this.Attributes[index].Value
                                 : (default_ == null) ? null
                                                      : default_.Value;
        }

        public ArchiveValue GetValue(int index, Lazy<ArchiveValue> default_ = null)
        {
            return (index < this.Values.Count) ? this.Values[index]
                                               : (default_ == null) ? null
                                                                    : default_.Value;
        }

        public ArchiveObject GetChild(string name, Lazy<ArchiveObject> default_ = null)
        {
            var index = this.Children.FindIndex(a => a.Name == name);
            return (index != -1) ? this.Children[index]
                                 : (default_ == null) ? null
                                                      : default_.Value;
        }

        public void AddValues(IEnumerable<ArchiveValue> values)
        {
            foreach(var value in values)
                this.AddValue(value);
        }

        public void SetAttributeAs<T>(string name, T value)
        {
            this.SetAttribute(name, ArchiveValue.Create<T>(value));
        }

        public void AddValueAs<T>(T value)
        {
            this.AddValue(ArchiveValue.Create<T>(value));
        }

        public T GetAttributeAs<T>(string name, Lazy<T> default_ = null)
        {
            var val = this.GetAttribute(name);
            return (val != null) ? val.Get<T>()
                                 : (default_ == null) ? default(T)
                                                      : default_.Value;
        }

        public T GetValueAs<T>(int index, Lazy<T> default_ = null)
        {
            var val = this.GetValue(index);
            return (val != null) ? val.Get<T>()
                                 : (default_ == null) ? default(T)
                                                      : default_.Value;
        }

        public ArchiveObject ExpectChild(string name)
        {
            var child = this.GetChild(name);
            if (child == null)
                throw new IndexOutOfRangeException($"No child called '{name}' was found");

            return child;
        }

        public ArchiveValue ExpectAttribute(string name)
        {
            var child = this.GetAttribute(name);
            if (child == null)
                throw new IndexOutOfRangeException($"No attribute called '{name}' was found");

            return child;
        }

        public ArchiveValue ExpectValue(int index)
        {
            var child = this.GetValue(index);
            if (child == null)
                throw new IndexOutOfRangeException($"No value at index {index}");

            return child;
        }

        public T ExpectAttributeAs<T>(string name)
        {
            return this.ExpectAttribute(name).Get<T>();
        }

        public T ExpectValueAs<T>(int index)
        {
            return this.ExpectValue(index).Get<T>();
        }
    }
}
