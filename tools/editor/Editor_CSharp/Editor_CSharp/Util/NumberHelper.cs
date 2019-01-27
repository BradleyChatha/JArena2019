using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Util
{
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
                    _Converters[typeof(float)] = v => Convert.ToSingle(v.Get<float>());
                    _Converters[typeof(int)] = v => Convert.ToInt32(v.Get<int>());
                }

                return _Converters;
            }
        }

        public static T ConvertValue<T>(ArchiveValue v)
        {
            return (T)Converters[v.CurrentType](v);
        }
    }
}
