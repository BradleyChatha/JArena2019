using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Util
{
    // Be witness to junior level design.
    public static class NumberHelper
    {
        private static Dictionary<Type, Converter<ArchiveValue, Object>> _Converters;
        public static Dictionary<Type, Converter<ArchiveValue, Object>> Converters
        {
            get
            {
                if (_Converters == null)
                {
                    _Converters = new Dictionary<Type, Converter<ArchiveValue, object>>();
                    _Converters[typeof(float)]  = v => Convert.ToSingle(v.Get<float>());
                    _Converters[typeof(int)]    = v => Convert.ToInt32(v.Get<int>());
                    _Converters[typeof(uint)]   = v => Convert.ToUInt32(v.Get<uint>());
                    _Converters[typeof(double)] = v => Convert.ToDouble(v.Get<double>());
                    _Converters[typeof(long)]   = v => Convert.ToInt64(v.Get<long>());
                }

                return _Converters;
            }
        }

        private static Dictionary<Type, Converter<Object, ArchiveValue>> _Makers;
        public static Dictionary<Type, Converter<Object, ArchiveValue>> Makers
        {
            get
            {
                if(_Makers == null)
                {
                    _Makers = new Dictionary<Type, Converter<object, ArchiveValue>>();
                    _Makers[typeof(float)]  = v => { var av = new ArchiveValue(); av.SetValue((float)v); return av; };
                    _Makers[typeof(int)]    = v => { var av = new ArchiveValue(); av.SetValue((int)v); return av; };
                    _Makers[typeof(uint)]   = v => { var av = new ArchiveValue(); av.SetValue((uint)v); return av; };
                    _Makers[typeof(double)] = v => { var av = new ArchiveValue(); av.SetValue((double)v); return av; };
                    _Makers[typeof(long)]   = v => { var av = new ArchiveValue(); av.SetValue((long)v); return av; };
                }

                return _Makers;
            }
        }

        private static Dictionary<string, Converter<string, ArchiveValue>> _StringConverters;
        public static Dictionary<string, Converter<string, ArchiveValue>> StringConverters
        {
            get
            {
                if (_StringConverters == null)
                {
                    _StringConverters = new Dictionary<string, Converter<string, ArchiveValue>>();
                    _StringConverters["float"]  = v => { var av = new ArchiveValue(); av.SetValue(Convert.ToSingle(v)); return av;};
                    _StringConverters["int"]    = v => { var av = new ArchiveValue(); av.SetValue(Convert.ToInt32(v)); return av; };
                    _StringConverters["uint"]   = v => { var av = new ArchiveValue(); av.SetValue(Convert.ToUInt32(v)); return av; };
                    _StringConverters["double"] = v => { var av = new ArchiveValue(); av.SetValue(Convert.ToDouble(v)); return av; };
                    _StringConverters["long"]   = v => { var av = new ArchiveValue(); av.SetValue(Convert.ToInt64(v)); return av; };
                }

                return _StringConverters;
            }
        }

        public static T ConvertValue<T>(ArchiveValue v)
        {
            return (T)Converters[v.CurrentType](v);
        }

        public static ArchiveValue MakeValue<T>(T value)
        {
            return Makers[typeof(T)](value);
        }

        public static ArchiveValue MakeValue(string value, string type)
        {
            return StringConverters[type](value);
        }
    }
}
